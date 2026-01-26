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
        log_sync("Team", data["id"], action)
        team
      end

      def delete_from_linear(linear_id)
        team = Team.find_by(linear_id: linear_id)
        return unless team

        team.destroy!
        log_sync("Team", linear_id, "delete")
      end
    end
  end
end
