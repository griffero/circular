# frozen_string_literal: true

module Sync
  class WorkflowStateSync < BaseSync
    class << self
      def upsert_from_linear(data)
        team = Team.find_by(linear_id: data.dig("team", "id"))
        return unless team

        state = WorkflowState.find_or_initialize_by(linear_id: data["id"])
        action = state.new_record? ? "create" : "update"

        state.assign_attributes(
          team: team,
          name: data["name"],
          color: data["color"],
          description: data["description"],
          state_type: data["type"],
          position: data["position"] || 0
        )

        state.save!
        log_sync("WorkflowState", data["id"], action)
        state
      end

      def delete_from_linear(linear_id)
        state = WorkflowState.find_by(linear_id: linear_id)
        return unless state

        state.destroy!
        log_sync("WorkflowState", linear_id, "delete")
      end
    end
  end
end
