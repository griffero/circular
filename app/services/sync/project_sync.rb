# frozen_string_literal: true

module Sync
  class ProjectSync < BaseSync
    class << self
      def upsert_from_linear(data)
        project = Project.find_or_initialize_by(linear_id: data["id"])
        action = project.new_record? ? "create" : "update"

        # Find lead
        lead = data.dig("lead", "id") ? User.find_by(linear_id: data.dig("lead", "id")) : nil

        # Map Linear state to Circular status
        status = map_state_to_status(data["state"])

        project.assign_attributes(
          name: data["name"],
          slug: data["slugId"] || data["name"].parameterize,
          slug_id: data["slugId"],
          description: data["description"],
          icon: data["icon"],
          color: data["color"],
          state: data["state"],
          status: status,
          start_date: data["startDate"],
          target_date: data["targetDate"],
          progress: data["progress"] || 0,
          health: data["health"],
          lead: lead
        )

        project.save!

        # Sync project teams
        sync_teams(project, data.dig("teams", "nodes") || [])

        # Sync project memberships
        sync_members(project, data) if data["members"]

        log_sync("Project", data["id"], action)
        project
      end

      def delete_from_linear(linear_id)
        project = Project.find_by(linear_id: linear_id)
        return unless project

        project.destroy!
        log_sync("Project", linear_id, "delete")
      end

      private

      def sync_teams(project, teams_data)
        team_ids = teams_data.map { |t| Team.find_by(linear_id: t["id"])&.id }.compact
        project.team_ids = team_ids
      end

      def sync_members(project, data)
        member_linear_ids = data.dig("members", "nodes")&.map { |m| m["id"] } || []
        return if member_linear_ids.empty?

        # Find users by their linear_id
        users = User.where(linear_id: member_linear_ids)

        # Get current member ids
        current_member_ids = project.project_memberships.pluck(:user_id)

        # Add new members
        users_to_add = users.where.not(id: current_member_ids)
        users_to_add.each do |user|
          ProjectMembership.find_or_create_by!(project: project, user: user) do |pm|
            pm.role = "member"
          end
        end
      end

      def map_state_to_status(state)
        case state
        when "started"
          "active"
        when "paused"
          "paused"
        when "completed"
          "completed"
        when "canceled"
          "canceled"
        else
          "active"
        end
      end
    end
  end
end
