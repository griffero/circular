# frozen_string_literal: true

module Sync
  class TeamSync < BaseSync
    class << self
      def upsert_from_linear(data)
        team = Team.find_or_initialize_by(linear_id: data["id"])
        action = team.new_record? ? "create" : "update"

        team.assign_attributes(
          name: data["name"],
          key: data["key"],
          description: data["description"],
          color: data["color"],
          icon: data["icon"]
        )

        team.save!

        # Sync team memberships if members data is present
        sync_team_memberships(team, data) if data["members"]

        log_sync("Team", data["id"], action)
        team
      end

      def delete_from_linear(linear_id)
        team = Team.find_by(linear_id: linear_id)
        return unless team

        team.destroy!
        log_sync("Team", linear_id, "delete")
      end

      private

      def sync_team_memberships(team, data)
        member_linear_ids = data.dig("members", "nodes")&.map { |m| m["id"] } || []
        return if member_linear_ids.empty?

        # Find users by their linear_id
        users = User.where(linear_id: member_linear_ids)

        # Get current member ids
        current_member_ids = team.team_memberships.pluck(:user_id)
        new_member_ids = users.pluck(:id)

        # Add new members
        users_to_add = users.where.not(id: current_member_ids)
        users_to_add.each do |user|
          TeamMembership.find_or_create_by!(team: team, user: user) do |tm|
            tm.role = "member"
          end
        end

        # Remove members no longer in Linear (optional - you might want to keep them)
        # team.team_memberships.where.not(user_id: new_member_ids).destroy_all
      end
    end
  end
end
