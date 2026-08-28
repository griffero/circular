# frozen_string_literal: true

# Define the transformer class inline to avoid autoloading issues
class LowerCamelTransformer < Blueprinter::Transformer
  def transform(hash, _object, _options)
    hash.transform_keys! { |key| key.to_s.camelize(:lower).to_sym }
  end
end

Blueprinter.configure do |config|
  config.generator = Oj
  config.datetime_format = ->(datetime) { datetime&.iso8601 }
  config.default_transformers = [ LowerCamelTransformer ]
end
