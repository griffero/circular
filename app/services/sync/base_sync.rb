# frozen_string_literal: true

module Sync
  class BaseSync
    class << self
      def upsert_from_linear(data)
        raise NotImplementedError
      end

      def delete_from_linear(linear_id)
        raise NotImplementedError
      end

      protected

      def log_sync(entity_type, linear_id, action, source = "manual")
        SyncLog.create!(
          entity_type: entity_type,
          linear_id: linear_id,
          action: action,
          source: source,
          status: "processed",
          processed_at: Time.current
        )
      rescue StandardError => e
        Rails.logger.error("Failed to log sync: #{e.message}")
      end
    end
  end
end
