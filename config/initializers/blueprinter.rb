# frozen_string_literal: true

Blueprinter.configure do |config|
  config.generator = Oj
  config.datetime_format = ->(datetime) { datetime&.iso8601 }
end
