# frozen_string_literal: true

module Sync
  class LabelSync < BaseSync
    class << self
      def upsert_from_linear(data)
        label = Label.find_or_initialize_by(linear_id: data["id"])
        action = label.new_record? ? "create" : "update"

        # Find team (nil for global labels)
        team = data.dig("team", "id") ? Team.find_by(linear_id: data.dig("team", "id")) : nil

        # Find parent label if exists
        parent = data.dig("parent", "id") ? Label.find_by(linear_id: data.dig("parent", "id")) : nil

        label.assign_attributes(
          team: team,
          parent: parent,
          name: data["name"],
          color: data["color"] || "#808080",
          description: data["description"],
          is_group: data["isGroup"] || false
        )

        label.save!
        log_sync("Label", data["id"], action)
        label
      end

      def delete_from_linear(linear_id)
        label = Label.find_by(linear_id: linear_id)
        return unless label

        label.destroy!
        log_sync("Label", linear_id, "delete")
      end
    end
  end
end
