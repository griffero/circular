# frozen_string_literal: true

module LinearOrigin
  extend ActiveSupport::Concern

  def from_linear?
    linear_id.present?
  end

  def circular_native?
    linear_id.nil?
  end
end
