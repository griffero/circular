# frozen_string_literal: true

# TEMPORARY DEBUG CONTROLLER - REMOVE AFTER TESTING
class DebugController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def status
    data = {
      timestamp: Time.current.iso8601,
      slack_bot_token_present: ENV["SLACK_BOT_TOKEN"].present?,
      slack_bot_token_prefix: ENV["SLACK_BOT_TOKEN"]&.slice(0, 10),
      users_count: User.count,
      teams_count: Team.count,
      projects_count: Project.count,
      slack_emojis_count: SlackEmoji.count,
      sample_emojis: SlackEmoji.limit(5).pluck(:name, :url).to_h,
      tables: ActiveRecord::Base.connection.tables.sort
    }
    render json: data
  rescue => e
    render json: { error: e.class.to_s, message: e.message, backtrace: e.backtrace.first(5) }
  end
end
