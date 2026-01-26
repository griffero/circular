# frozen_string_literal: true

module Sync
  class CycleSync < BaseSync
    class << self
      def upsert_from_linear(data)
        team = Team.find_by(linear_id: data.dig("team", "id"))
        return unless team

        cycle = Cycle.find_or_initialize_by(linear_id: data["id"])
        action = cycle.new_record? ? "create" : "update"

        cycle.assign_attributes(
          team: team,
          number: data["number"],
          name: data["name"],
          description: data["description"],
          starts_at: data["startsAt"],
          ends_at: data["endsAt"],
          progress: data["progress"] || 0,
          completed_at: data["completedAt"]
        )

        cycle.save!
        log_sync("Cycle", data["id"], action)
        cycle
      end

      def delete_from_linear(linear_id)
        cycle = Cycle.find_by(linear_id: linear_id)
        return unless cycle

        cycle.destroy!
        log_sync("Cycle", linear_id, "delete")
      end
    end
  end
end
