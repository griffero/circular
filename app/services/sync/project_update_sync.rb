# frozen_string_literal: true

module Sync
  class ProjectUpdateSync < BaseSync
    class << self
      def upsert_from_linear(data)
        project_update = ProjectUpdate.find_or_initialize_by(linear_id: data["id"])
        action = project_update.new_record? ? "create" : "update"

        # Find project and user
        project = Project.find_by(linear_id: data.dig("project", "id"))
        user = User.find_by(linear_id: data.dig("user", "id"))

        # Skip if we don't have the project or user
        unless project
          Rails.logger.warn "ProjectUpdateSync: Skipping update #{data["id"]} - project not found: #{data.dig("project", "id")}"
          return nil
        end
        unless user
          Rails.logger.warn "ProjectUpdateSync: Skipping update #{data["id"]} - user not found: #{data.dig("user", "id")}"
          return nil
        end

        project_update.assign_attributes(
          project: project,
          user: user,
          body: data["body"],
          health: data["health"],
          edited_at: data["editedAt"],
          created_at: data["createdAt"] || Time.current,
          updated_at: data["updatedAt"] || Time.current
        )

        project_update.save!
        log_sync("ProjectUpdate", data["id"], action)

        # Sync comments if present
        if data["comments"] && data["comments"]["nodes"]
          data["comments"]["nodes"].each do |comment_data|
            ProjectUpdateCommentSync.sync(comment_data, project_update)
          end
        end

        project_update
      end

      def delete_from_linear(linear_id)
        project_update = ProjectUpdate.find_by(linear_id: linear_id)
        return unless project_update

        project_update.destroy!
        log_sync("ProjectUpdate", linear_id, "delete")
      end
    end
  end
end
