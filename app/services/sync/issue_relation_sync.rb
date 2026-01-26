# frozen_string_literal: true

module Sync
  class IssueRelationSync < BaseSync
    class << self
      def upsert_from_linear(data)
        issue = Issue.find_by(linear_id: data.dig("issue", "id"))
        related_issue = Issue.find_by(linear_id: data.dig("relatedIssue", "id"))

        return unless issue && related_issue

        relation = IssueRelation.find_or_initialize_by(linear_id: data["id"])
        action = relation.new_record? ? "create" : "update"

        relation.assign_attributes(
          issue: issue,
          related_issue: related_issue,
          relation_type: map_relation_type(data["type"])
        )

        relation.save!
        log_sync("IssueRelation", data["id"], action)
        relation
      end

      def delete_from_linear(linear_id)
        relation = IssueRelation.find_by(linear_id: linear_id)
        return unless relation

        relation.destroy!
        log_sync("IssueRelation", linear_id, "delete")
      end

      private

      def map_relation_type(linear_type)
        case linear_type
        when "blocks"
          "blocks"
        when "duplicate"
          "duplicate"
        else
          "related"
        end
      end
    end
  end
end
