# frozen_string_literal: true

Blueprinter.configure do |config|
  config.generator = Oj
  config.datetime_format = ->(datetime) { datetime&.iso8601 }
  # Transform snake_case keys to camelCase for JavaScript consumption
  config.transform_key = ->(key) { key.to_s.camelize(:lower) }
end
