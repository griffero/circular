# frozen_string_literal: true

class LinearWebhookHandler
  ENTITY_HANDLERS = {
    "Issue" => Sync::IssueSync,
    "Project" => Sync::ProjectSync,
    "User" => Sync::UserSync,
    "Team" => Sync::TeamSync,
    "Label" => Sync::LabelSync,
    "IssueLabel" => Sync::LabelSync,
    "Cycle" => Sync::CycleSync,
    "Comment" => Sync::CommentSync,
    "WorkflowState" => Sync::WorkflowStateSync,
    "IssueRelation" => Sync::IssueRelationSync,
    "Attachment" => Sync::AttachmentSync
  }.freeze

  def initialize(payload)
    @payload = payload
    @action = payload["action"] # create, update, remove
    @type = payload["type"]
    @data = payload["data"]
  end

  def process
    Rails.logger.info("Processing Linear webhook: #{@type} #{@action}")

    handler_class = ENTITY_HANDLERS[@type]
    unless handler_class
      Rails.logger.warn("No handler for entity type: #{@type}")
      return { success: false, message: "Unknown entity type: #{@type}" }
    end

    case @action
    when "create", "update"
      # For create/update, we need to fetch full data from Linear API
      # since webhook payload may not contain all fields
      handler_class.upsert_from_linear(@data)
      { success: true, action: @action, type: @type }
    when "remove"
      handler_class.delete_from_linear(@data["id"])
      { success: true, action: @action, type: @type }
    else
      Rails.logger.warn("Unknown action: #{@action}")
      { success: false, message: "Unknown action: #{@action}" }
    end
  rescue StandardError => e
    Rails.logger.error("Error processing webhook: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
    { success: false, error: e.message }
  end
end
