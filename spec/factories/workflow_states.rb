# frozen_string_literal: true

FactoryBot.define do
  factory :workflow_state do
    association :team
    sequence(:name) { |n| "State #{n}" }
    color { "#5e6ad2" }
    state_type { "unstarted" }
    sequence(:position) { |n| n.to_f }
  end
end
