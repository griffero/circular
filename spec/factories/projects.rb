# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    name { Faker::App.name }
    sequence(:slug) { |n| "project-#{n}" }
    description { Faker::Lorem.sentence }
    color { Faker::Color.hex_color }
    status { "active" }
    privacy { "public" }

    trait :private do
      privacy { "private" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :canceled do
      status { "canceled" }
    end
  end
end
