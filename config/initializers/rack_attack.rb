# frozen_string_literal: true

if Rails.env.development? && ENV.fetch("RACK_ATTACK_DEV_ENABLED", "0") != "1"
  Rack::Attack.enabled = false
  return
end

class Rack::Attack
  # Throttle all requests by IP (60rpm)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Throttle POST requests to /api/v1/auth/* by IP
  throttle("auth/ip", limit: 5, period: 20.seconds) do |req|
    if req.path.start_with?("/api/v1/auth") && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /api/v1/auth/* by email param
  throttle("auth/email", limit: 5, period: 1.minute) do |req|
    if req.path.start_with?("/api/v1/auth") && req.post?
      # Return the email if present, nil otherwise
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # Block suspicious requests
  blocklist("block bad requests") do |req|
    Rack::Attack::Fail2Ban.filter("pentest-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      req.path.include?("/etc/passwd") ||
        req.path.include?("wp-admin") ||
        req.path.include?(".php")
    end
  end
end

# Custom response for throttled requests
Rack::Attack.throttled_responder = lambda do |request|
  [
    429,
    { "Content-Type" => "application/json" },
    [{ error: "Rate limit exceeded. Please retry later." }.to_json]
  ]
end
