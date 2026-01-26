# frozen_string_literal: true

module Sync
  class IssueSync < BaseSync
    class << self
      def upsert_from_linear(data)
        team = Team.find_by(linear_id: data.dig("team", "id"))
        return unless team

        issue = Issue.find_or_initialize_by(linear_id: data["id"])
        action = issue.new_record? ? "create" : "update"

        # Find related entities
        creator = User.find_by(linear_id: data.dig("creator", "id"))
        assignee = data.dig("assignee", "id") ? User.find_by(linear_id: data.dig("assignee", "id")) : nil
        project = data.dig("project", "id") ? Project.find_by(linear_id: data.dig("project", "id")) : nil
        cycle = data.dig("cycle", "id") ? Cycle.find_by(linear_id: data.dig("cycle", "id")) : nil
        workflow_state = data.dig("state", "id") ? WorkflowState.find_by(linear_id: data.dig("state", "id")) : nil
        parent = data.dig("parent", "id") ? Issue.find_by(linear_id: data.dig("parent", "id")) : nil

        # For new issues, we need to set team first for identifier generation
        if issue.new_record?
          issue.team = team
          issue.creator = creator || User.first # Fallback to first user if creator not found
          # Set identifier and number from Linear
          issue.identifier = data["identifier"]
          issue.number = data["number"]
        end

        issue.assign_attributes(
          team: team,
          creator: creator || issue.creator,
          assignee: assignee,
          project: project,
          cycle: cycle,
          workflow_state: workflow_state,
          parent: parent,
          title: data["title"],
          description: data["description"],
          priority: data["priority"] || 0,
          estimate: data["estimate"],
          due_date: data["dueDate"],
          sort_order: data["sortOrder"]&.to_i || 0,
          started_at: data["startedAt"],
          completed_at: data["completedAt"],
          canceled_at: data["canceledAt"],
          archived_at: data["archivedAt"]
        )

        # Skip identifier generation callback for imported issues
        issue.save!(validate: false)

        # Sync labels
        sync_labels(issue, data.dig("labels", "nodes") || [])

        log_sync("Issue", data["id"], action)
        issue
      end

      def delete_from_linear(linear_id)
        issue = Issue.find_by(linear_id: linear_id)
        return unless issue

        issue.destroy!
        log_sync("Issue", linear_id, "delete")
      end

      private

      def sync_labels(issue, labels_data)
        label_ids = labels_data.map { |l| Label.find_by(linear_id: l["id"])&.id }.compact
        issue.label_ids = label_ids
      end
    end
  end
end
