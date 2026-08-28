# frozen_string_literal: true

module Api
  module V1
    class IssuesController < BaseController
      before_action :set_issue, only: %i[show update destroy]

      def index
        issues = Issue.includes(
          :creator,
          :assignee,
          :team,
          :project,
          :labels,
          :workflow_state,
          :attachments,
          :blocked_issues,
          :blocking_issues
        )

        # Filter by team
        issues = issues.by_team(params[:team_id]) if params[:team_id].present?

        # Filter by project
        issues = issues.by_project(params[:project_id]) if params[:project_id].present?

        # Filter by assignee
        if params[:assignee_id].present?
          issues = params[:assignee_id] == "unassigned" ? issues.unassigned : issues.by_assignee(params[:assignee_id])
        end

        # Filter by creator
        issues = issues.where(creator_id: params[:creator_id]) if params[:creator_id].present?

        # Filter by status
        if params[:statuses].present?
          statuses = params[:statuses].to_s.split(",").map(&:strip).reject(&:blank?)
          issues = issues.where(status: statuses) if statuses.any?
        elsif params[:status].present?
          issues = issues.where(status: params[:status])
        end

        # Filter by workflow_state
        issues = issues.where(workflow_state_id: params[:workflow_state_id]) if params[:workflow_state_id].present?

        # Filter by workflow_state type (triage/backlog/unstarted/started/completed/canceled).
        # Keep legacy backlog issues (without workflow_state_id) visible in backlog mode.
        if params[:workflow_state_type].present?
          issues = apply_workflow_state_type_filter(issues, params[:workflow_state_type])
        end

        # Filter by cycle
        issues = issues.where(cycle_id: params[:cycle_id]) if params[:cycle_id].present?

        # Filter by priority
        issues = issues.by_priority(params[:priority]) if params[:priority].present?

        # Filter for my issues
        issues = issues.by_assignee(current_user.id) if params[:my_issues] == "true"

        # Filter for issues subscribed by current user
        if params[:subscribed] == "true"
          issues = issues.joins(:issue_subscriptions).where(issue_subscriptions: { user_id: current_user.id }).distinct
        end

        # Search
        issues = issues.search(params[:q]) if params[:q].present?

        # Sorting
        issues = apply_sort(issues)

        # Pagination
        page = (params[:page] || 1).to_i
        per_page = [ (params[:per_page] || 100).to_i, 500 ].min
        total_count = issues.count
        issues = issues.offset((page - 1) * per_page).limit(per_page)

        render json: {
          issues: IssueSerializer.render_as_hash(issues, view: :list),
          meta: {
            page: page,
            per_page: per_page,
            total_count: total_count,
            total_pages: (total_count.to_f / per_page).ceil
          }
        }
      end

      def show
        render json: {
          issue: IssueSerializer.render_as_hash(@issue, view: :detailed)
        }
      end

      def create
        team = Team.find_by!(id: params[:team_id])
        issue = team.issues.new(issue_params)
        issue.creator = current_user

        if issue.save
          broadcast_issue_created(issue)

          render json: {
            issue: IssueSerializer.render_as_hash(issue, view: :list)
          }, status: :created
        else
          render json: { error: issue.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        return if reject_linear_record!(@issue)

        if @issue.update(issue_params)
          broadcast_issue_updated(@issue)

          render json: {
            issue: IssueSerializer.render_as_hash(@issue, view: :list)
          }
        else
          render json: { error: @issue.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        return if reject_linear_record!(@issue)

        @issue.destroy!
        broadcast_issue_deleted(@issue)
        head :no_content
      end

      def bulk
        issue_ids = params[:issue_ids] || []
        updates = params[:updates] || {}

        issues = Issue.where(id: issue_ids)
        skipped_ids = issues.select(&:from_linear?).map(&:id)
        editable_issues = issues.reject(&:from_linear?)

        editable_issues.each do |issue|
          issue.update(updates.permit(:status, :priority, :assignee_id, :project_id))
          broadcast_issue_updated(issue)
        end

        render json: {
          issues: IssueSerializer.render_as_hash(issues.reload, view: :list),
          skipped_ids: skipped_ids
        }
      end

      private

      def set_issue
        @issue = Issue.includes(
          :creator, :assignee, :team, :project, :labels,
          :workflow_state, :cycle, :attachments,
          sub_issues: [ :assignee, :workflow_state ],
          parent: [ :assignee, :workflow_state ]
        ).find(params[:id])
      end

      def issue_params
        params.require(:issue).permit(
          :title, :description, :status, :priority,
          :assignee_id, :project_id, :parent_id,
          :workflow_state_id, :cycle_id,
          :due_date, :estimate, :sort_order,
          label_ids: []
        )
      end

      def sort_direction
        params[:direction] == "asc" ? :asc : :desc
      end

      def apply_sort(scope)
        case params[:sort]
        when "created_at"
          scope.order(created_at: sort_direction, id: :asc)
        when "updated_at"
          scope.order(updated_at: sort_direction, created_at: :desc, id: :asc)
        when "priority"
          # Keep no-priority items at the end in both directions for stable triage UX.
          priority_direction = sort_direction == :asc ? "ASC" : "DESC"
          scope.order(
            Arel.sql("CASE WHEN issues.priority = 0 THEN 1 ELSE 0 END ASC"),
            Arel.sql("CASE WHEN issues.priority = 0 THEN NULL ELSE issues.priority END #{priority_direction}"),
            updated_at: :desc,
            id: :asc
          )
        when "due_date"
          # Keep undated issues grouped after dated ones to avoid noisy ordering.
          due_date_direction = sort_direction == :asc ? "ASC" : "DESC"
          scope.order(
            Arel.sql("CASE WHEN issues.due_date IS NULL THEN 1 ELSE 0 END ASC"),
            Arel.sql("issues.due_date #{due_date_direction}"),
            created_at: :desc,
            id: :asc
          )
        else
          scope.order(updated_at: :desc, created_at: :desc, id: :asc)
        end
      end

      def apply_workflow_state_type_filter(scope, workflow_state_type)
        workflow_state_type = workflow_state_type.to_s
        filtered = scope.left_joins(:workflow_state).where(workflow_states: { state_type: workflow_state_type })

        return filtered unless workflow_state_type == "backlog"

        filtered.or(scope.where(workflow_state_id: nil, status: "backlog"))
      end

      # Realtime broadcasts
      def broadcast_issue_created(issue)
        ActionCable.server.broadcast(
          "issues",
          { type: "issue.created", issue: IssueSerializer.render_as_hash(issue, view: :list) }
        )
        ActionCable.server.broadcast(
          "team_#{issue.team_id}",
          { type: "issue.created", issue: IssueSerializer.render_as_hash(issue, view: :list) }
        )
      end

      def broadcast_issue_updated(issue)
        ActionCable.server.broadcast(
          "issues",
          { type: "issue.updated", issue: IssueSerializer.render_as_hash(issue, view: :list) }
        )
        ActionCable.server.broadcast(
          "team_#{issue.team_id}",
          { type: "issue.updated", issue: IssueSerializer.render_as_hash(issue, view: :list) }
        )
        ActionCable.server.broadcast(
          "issue_#{issue.id}",
          { type: "issue.updated", issue: IssueSerializer.render_as_hash(issue, view: :detailed) }
        )
      end

      def broadcast_issue_deleted(issue)
        ActionCable.server.broadcast(
          "issues",
          { type: "issue.deleted", issue_id: issue.id }
        )
        ActionCable.server.broadcast(
          "team_#{issue.team_id}",
          { type: "issue.deleted", issue_id: issue.id }
        )
      end
    end
  end
end
