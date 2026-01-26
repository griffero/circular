# frozen_string_literal: true

module Sync
  class AttachmentSync < BaseSync
    class << self
      # Called from webhook - data contains issue reference
      def upsert_from_linear(data)
        # Find issue from webhook data
        issue = Issue.find_by(linear_id: data.dig("issue", "id"))
        return unless issue

        upsert_with_issue(data, issue)
      end

      # Called from importer with explicit issue
      def upsert_with_issue(data, issue)
        attachment = Attachment.find_or_initialize_by(linear_id: data["id"])
        action = attachment.new_record? ? "create" : "update"

        attachment.assign_attributes(
          issue: issue,
          title: data["title"],
          url: data["url"]
        )

        attachment.save!
        log_sync("Attachment", data["id"], action)
        attachment
      end

      def delete_from_linear(linear_id)
        attachment = Attachment.find_by(linear_id: linear_id)
        return unless attachment

        attachment.destroy!
        log_sync("Attachment", linear_id, "delete")
      end
    end
  end
end
