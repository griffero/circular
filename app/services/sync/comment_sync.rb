# frozen_string_literal: true

module Sync
  class CommentSync < BaseSync
    class << self
      def upsert_from_linear(data)
        issue = Issue.find_by(linear_id: data.dig("issue", "id"))
        return unless issue

        user = User.find_by(linear_id: data.dig("user", "id"))
        return unless user

        comment = Comment.find_or_initialize_by(linear_id: data["id"])
        action = comment.new_record? ? "create" : "update"

        # Find parent comment if exists
        parent = data.dig("parent", "id") ? Comment.find_by(linear_id: data.dig("parent", "id")) : nil

        comment.assign_attributes(
          issue: issue,
          user: user,
          parent: parent,
          body: data["body"] || "",
          edited_at: data["editedAt"]
        )

        # Set created_at from Linear
        if comment.new_record? && data["createdAt"]
          comment.created_at = data["createdAt"]
        end

        comment.save!
        log_sync("Comment", data["id"], action)
        comment
      end

      def delete_from_linear(linear_id)
        comment = Comment.find_by(linear_id: linear_id)
        return unless comment

        comment.destroy!
        log_sync("Comment", linear_id, "delete")
      end
    end
  end
end
