# frozen_string_literal: true

module Webhooks
  class LinearController < ActionController::API
    before_action :verify_webhook_signature

    def receive
      payload = JSON.parse(request.body.read)

      # Log the incoming webhook
      sync_log = SyncLog.create!(
        entity_type: payload["type"] || "Unknown",
        linear_id: payload.dig("data", "id") || "unknown",
        action: payload["action"] || "unknown",
        source: "webhook",
        payload: payload,
        status: "pending"
      )

      # Process asynchronously
      LinearWebhookJob.perform_later(sync_log.id)

      head :ok
    rescue JSON::ParserError => e
      Rails.logger.error("Invalid JSON in Linear webhook: #{e.message}")
      head :bad_request
    rescue StandardError => e
      Rails.logger.error("Error processing Linear webhook: #{e.message}")
      head :internal_server_error
    end

    private

    def verify_webhook_signature
      signature = request.headers["Linear-Signature"]

      # In development, skip signature verification if no secret is set
      if Rails.env.development? && ENV["LINEAR_WEBHOOK_SECRET"].blank?
        Rails.logger.warn("Skipping webhook signature verification in development")
        return
      end

      webhook_secret = ENV["LINEAR_WEBHOOK_SECRET"]
      if webhook_secret.blank?
        Rails.logger.error("LINEAR_WEBHOOK_SECRET is not set")
        head :unauthorized
        return
      end

      if signature.blank?
        Rails.logger.error("Missing Linear-Signature header")
        head :unauthorized
        return
      end

      body = request.body.read
      request.body.rewind

      expected = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body)

      unless ActiveSupport::SecurityUtils.secure_compare(signature, expected)
        Rails.logger.error("Invalid webhook signature")
        head :unauthorized
      end
    end
  end
end
