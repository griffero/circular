# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module LinearClone
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])

    # API only mode but with sessions for cookie auth
    config.api_only = true

    # Add back session middleware for cookie-based auth
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore,
                          key: "_linear_clone_session",
                          expire_after: 30.days,
                          same_site: Rails.env.production? ? :none : :lax,
                          secure: Rails.env.production?

    # Time zone
    config.time_zone = "UTC"

    # ActiveJob backend
    config.active_job.queue_adapter = :sidekiq

    # Generators
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end
  end
end
