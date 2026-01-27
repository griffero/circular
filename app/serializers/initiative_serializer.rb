# frozen_string_literal: true

class InitiativeSerializer < Blueprinter::Base
  identifier :id

  fields :name, :slug, :description, :icon, :color, :status, :health,
         :target_year, :target_quarter, :target_date, :sort_order,
         :created_at, :updated_at

  field :target_display

  field :projects_progress do |initiative|
    initiative.projects_progress
  end

  association :owner, blueprint: UserSerializer, view: :minimal
  association :projects, blueprint: ProjectSerializer, view: :minimal

  view :minimal do
    fields :id, :name, :slug, :icon, :color, :status
  end

  view :with_projects do
    include_view :default
    association :projects, blueprint: ProjectSerializer, view: :with_teams
  end
end
