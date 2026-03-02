# frozen_string_literal: true

FactoryBot.define do
  factory :cycle do
    association :team
    sequence(:number) { |n| n }
    sequence(:name) { |n| "Cycle #{n}" }
    starts_at { Time.current.beginning_of_week }
    ends_at { Time.current.end_of_week }
  end
end
