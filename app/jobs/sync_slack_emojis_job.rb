# frozen_string_literal: true

class SyncSlackEmojisJob < ApplicationJob
  queue_as :sync

  def perform
    Rails.logger.info("Starting Slack emoji sync...")

    unless ENV["SLACK_BOT_TOKEN"].present?
      Rails.logger.warn("SLACK_BOT_TOKEN not configured, skipping emoji sync")
      return
    end

    begin
      client = SlackClient.new
      emojis = client.emoji_list

      sync_emojis(emojis)

      Rails.logger.info("Slack emoji sync completed: #{emojis.size} emojis processed")
    rescue SlackClient::RateLimitError => e
      Rails.logger.warn("Rate limited by Slack API, will retry later: #{e.message}")
      raise # Re-raise to trigger retry
    rescue SlackClient::AuthError => e
      Rails.logger.error("Slack authentication failed: #{e.message}")
      # Don't retry auth errors
    rescue StandardError => e
      Rails.logger.error("Slack emoji sync failed: #{e.message}")
      Rails.logger.error(e.backtrace.first(10).join("\n"))
      raise
    end
  end

  private

  def sync_emojis(emojis)
    current_names = emojis.keys
    aliases = {}

    # First pass: create all non-alias emojis
    emojis.each do |name, value|
      if value.start_with?("alias:")
        # Store aliases for second pass
        aliases[name] = value.sub("alias:", "")
      else
        SlackEmoji.find_or_initialize_by(name: name).tap do |emoji|
          emoji.url = value
          emoji.alias_for = nil
          emoji.save!
        end
      end
    end

    # Second pass: create alias emojis with resolved URLs
    aliases.each do |name, alias_for|
      # Resolve the URL by following the alias chain
      resolved_url = resolve_alias_url(emojis, alias_for)

      # Skip if we can't resolve the URL (broken alias)
      if resolved_url.nil?
        Rails.logger.warn("Skipping emoji '#{name}' - unable to resolve alias '#{alias_for}'")
        next
      end

      SlackEmoji.find_or_initialize_by(name: name).tap do |emoji|
        emoji.url = resolved_url
        emoji.alias_for = alias_for
        emoji.save!
      end
    end

    # Remove emojis that no longer exist in Slack
    deleted_count = SlackEmoji.where.not(name: current_names).delete_all
    Rails.logger.info("Removed #{deleted_count} obsolete emojis") if deleted_count.positive?
  end

  # Resolve an alias to its actual URL, following the chain if needed
  def resolve_alias_url(emojis, alias_name, depth = 0)
    return nil if depth > 10 # Prevent infinite loops

    value = emojis[alias_name]
    return nil if value.nil?

    if value.start_with?("alias:")
      resolve_alias_url(emojis, value.sub("alias:", ""), depth + 1)
    else
      value
    end
  end
end
