# frozen_string_literal: true

class CleanupSyncLogsJob < ApplicationJob
  queue_as :default

  # Keep sync logs for 7 days by default
  RETENTION_DAYS = ENV.fetch("SYNC_LOG_RETENTION_DAYS", 7).to_i

  def perform
    cutoff_date = RETENTION_DAYS.days.ago

    deleted_count = SyncLog.where("created_at < ?", cutoff_date).delete_all

    Rails.logger.info "[CleanupSyncLogsJob] Deleted #{deleted_count} sync logs older than #{cutoff_date}"

    deleted_count
  end
end
