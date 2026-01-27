# frozen_string_literal: true

class ProjectSerializer < Blueprinter::Base
  identifier :id

  fields :name, :slug, :slug_id, :description, :icon, :color, :privacy, :status,
         :state, :health, :progress, :start_date, :target_date, :created_at, :updated_at

  field :lead_id do |project|
    project.lead_id
  end

  field :linear_id do |project|
    project.linear_id
  end

  view :minimal do
    fields :id, :name, :slug, :icon, :color, :status, :state
  end

  view :with_lead do
    association :lead, blueprint: UserSerializer
  end

  view :with_members do
    association :members, blueprint: UserSerializer
  end

  view :with_teams do
    association :teams, blueprint: TeamSerializer
  end

  view :detailed do
    include_view :with_lead
    include_view :with_members
    include_view :with_teams
    field :settings
  end
end
