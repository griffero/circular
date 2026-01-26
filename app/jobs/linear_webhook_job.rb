# frozen_string_literal: true

class LinearWebhookJob < ApplicationJob
  queue_as :webhooks

  # Retry with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(sync_log_id)
    sync_log = SyncLog.find(sync_log_id)
    return if sync_log.processed?

    payload = sync_log.payload
    handler = LinearWebhookHandler.new(payload)
    result = handler.process

    if result[:success]
      sync_log.mark_processed!
      Rails.logger.info("Successfully processed webhook: #{sync_log.entity_type} #{sync_log.action}")
    else
      sync_log.mark_failed!(result[:error] || result[:message])
      Rails.logger.error("Failed to process webhook: #{result[:error] || result[:message]}")
    end
  rescue StandardError => e
    sync_log&.mark_failed!(e.message)
    raise # Re-raise to trigger retry
  end
end
