# frozen_string_literal: true

module RequestHelpers
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
