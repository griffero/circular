# frozen_string_literal: true

FactoryBot.define do
  factory :issue_subscription do
    association :issue
    association :user
  end
end
