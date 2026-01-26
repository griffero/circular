# frozen_string_literal: true

require "net/http"
require "json"
require "openssl"

class SlackClient
  BASE_URL = "https://slack.com/api"

  class Error < StandardError; end
  class RateLimitError < Error; end
  class AuthError < Error; end

  def initialize(token: ENV["SLACK_BOT_TOKEN"])
    @token = token
    raise Error, "SLACK_BOT_TOKEN is not set" if @token.blank?
  end

  # Fetch all custom emojis from the workspace
  # Returns a hash of emoji_name => url
  # Some emojis are aliases, they have format "alias:original_name"
  def emoji_list
    result = get("emoji.list")
    result["emoji"] || {}
  end

  private

  def get(endpoint, params = {})
    uri = URI("#{BASE_URL}/#{endpoint}")
    uri.query = URI.encode_www_form(params) if params.any?

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    http.open_timeout = 10

    # SSL configuration - skip CRL check which can cause issues with some CA certs
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    store = OpenSSL::X509::Store.new
    store.set_default_paths
    store.flags = OpenSSL::X509::V_FLAG_NO_CHECK_TIME
    http.cert_store = store

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["Content-Type"] = "application/json"

    response = http.request(request)

    case response.code.to_i
    when 200
      data = JSON.parse(response.body)

      unless data["ok"]
        error = data["error"] || "Unknown error"
        raise AuthError, "Slack API error: #{error}" if %w[invalid_auth token_revoked not_authed].include?(error)

        raise Error, "Slack API error: #{error}"
      end

      data
    when 429
      retry_after = response["Retry-After"]&.to_i || 60
      raise RateLimitError, "Rate limited by Slack API. Retry after #{retry_after} seconds"
    else
      raise Error, "HTTP #{response.code}: #{response.body}"
    end
  end
end
