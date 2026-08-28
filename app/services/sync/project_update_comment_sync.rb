# frozen_string_literal: true

module Sync
  class ProjectUpdateCommentSync
    class << self
      def sync(data, project_update)
        return unless data && project_update

        comment = ProjectUpdateComment.find_or_initialize_by(linear_id: data["id"])
        action = comment.new_record? ? "create" : "update"

        # Find user by Linear ID
        user = User.find_by(linear_id: data.dig("user", "id"))
        unless user
          Rails.logger.warn "ProjectUpdateCommentSync: User not found for linear_id #{data.dig("user", "id")}"
          return
        end

        comment.assign_attributes(
          project_update: project_update,
          user: user,
          body: data["body"],
          created_at: data["createdAt"],
          updated_at: data["updatedAt"]
        )

        comment.save!
        comment
      rescue StandardError => e
        Rails.logger.error "ProjectUpdateCommentSync error: #{e.message}"
        nil
      end

      def delete(linear_id)
        comment = ProjectUpdateComment.find_by(linear_id: linear_id)
        return unless comment

        comment.destroy!
      end
    end
  end
end
