# frozen_string_literal: true

module Api
  module V1
    class IssuesController < BaseController
      before_action :set_issue, only: %i[show update destroy]

      def index
        issues = Issue.includes(:creator, :assignee, :team, :project, :labels, :workflow_state)

        # Filter by team
        issues = issues.by_team(params[:team_id]) if params[:team_id].present?

        # Filter by project
        issues = issues.by_project(params[:project_id]) if params[:project_id].present?

        # Filter by assignee
        if params[:assignee_id].present?
          issues = params[:assignee_id] == "unassigned" ? issues.unassigned : issues.by_assignee(params[:assignee_id])
        end

        # Filter by status
        issues = issues.where(status: params[:status]) if params[:status].present?

        # Filter by priority
        issues = issues.by_priority(params[:priority]) if params[:priority].present?

        # Filter for my issues
        issues = issues.by_assignee(current_user.id) if params[:my_issues] == "true"

        # Search
        issues = issues.search(params[:q]) if params[:q].present?

        # Sorting
        case params[:sort]
        when "created_at"
          issues = issues.order(created_at: sort_direction)
        when "updated_at"
          issues = issues.order(updated_at: sort_direction)
        when "priority"
          issues = issues.order(priority: sort_direction)
        when "due_date"
          issues = issues.order(due_date: sort_direction)
        else
          issues = issues.order(sort_order: :asc, created_at: :desc)
        end

        render json: {
          issues: IssueSerializer.render_as_hash(issues, view: :list)
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
        @issue.destroy!
        broadcast_issue_deleted(@issue)
        head :no_content
      end

      def bulk
        issue_ids = params[:issue_ids] || []
        updates = params[:updates] || {}

        issues = Issue.where(id: issue_ids)

        issues.each do |issue|
          issue.update(updates.permit(:status, :priority, :assignee_id, :project_id))
          broadcast_issue_updated(issue)
        end

        render json: {
          issues: IssueSerializer.render_as_hash(issues.reload, view: :list)
        }
      end

      private

      def set_issue
        @issue = Issue.find(params[:id])
      end

      def issue_params
        params.require(:issue).permit(
          :title, :description, :status, :priority,
          :assignee_id, :project_id, :parent_id,
          :due_date, :estimate, :sort_order,
          label_ids: []
        )
      end

      def sort_direction
        params[:direction] == "asc" ? :asc : :desc
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
