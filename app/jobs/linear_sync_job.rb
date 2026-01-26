# frozen_string_literal: true

class LinearSyncJob < ApplicationJob
  queue_as :sync

  CACHE_KEY = "linear_sync:last_run"

  def perform
    Rails.logger.info("Starting Linear sync job...")

    # Get last sync time
    last_sync = last_sync_time
    Rails.logger.info("Syncing changes since: #{last_sync}")

    begin
      importer = LinearImporter.new
      stats = importer.import_changes_since(last_sync)

      # Update last sync time on success
      update_last_sync_time

      Rails.logger.info("Linear sync completed: #{stats.inspect}")
    rescue LinearClient::RateLimitError => e
      Rails.logger.warn("Rate limited by Linear API, will retry later: #{e.message}")
      raise # Re-raise to trigger retry
    rescue StandardError => e
      Rails.logger.error("Linear sync failed: #{e.message}")
      Rails.logger.error(e.backtrace.first(10).join("\n"))
      raise
    end
  end

  private

  def last_sync_time
    cached = Rails.cache.read(CACHE_KEY)
    return cached if cached.present?

    # Default to 1 hour ago for first run
    1.hour.ago
  end

  def update_last_sync_time
    Rails.cache.write(CACHE_KEY, Time.current, expires_in: 1.day)
  end
end
