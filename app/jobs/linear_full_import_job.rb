# frozen_string_literal: true

class LinearFullImportJob < ApplicationJob
  queue_as :sync

  def perform(entity_type = nil)
    client = LinearClient.new

    case entity_type
    when "comments"
      import_comments(client)
    when "issue_relations"
      import_issue_relations(client)
    when nil
      # Full import
      import_comments(client)
      import_issue_relations(client)
    end
  end

  private

  def import_comments(client)
    Rails.logger.info("Starting comments import...")
    count = 0
    client.comments.each do |comment_data|
      Sync::CommentSync.upsert_from_linear(comment_data)
      count += 1
      Rails.logger.info("Imported #{count} comments...") if (count % 500).zero?
    end
    Rails.logger.info("Completed importing #{count} comments")
  end

  def import_issue_relations(client)
    Rails.logger.info("Starting issue relations import...")
    count = 0
    client.issue_relations.each do |rel_data|
      Sync::IssueRelationSync.upsert_from_linear(rel_data)
      count += 1
      Rails.logger.info("Imported #{count} issue relations...") if (count % 100).zero?
    end
    Rails.logger.info("Completed importing #{count} issue relations")
  end
end
