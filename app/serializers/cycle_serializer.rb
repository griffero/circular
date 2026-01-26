# frozen_string_literal: true

class CycleSerializer < Blueprinter::Base
  identifier :id

  fields :number, :name, :description, :starts_at, :ends_at, :progress,
         :completed_at, :created_at, :updated_at

  field :team_id do |cycle|
    cycle.team_id
  end

  field :linear_id do |cycle|
    cycle.linear_id
  end

  field :display_name do |cycle|
    cycle.display_name
  end

  field :active do |cycle|
    cycle.active?
  end

  view :with_team do
    association :team, blueprint: TeamSerializer
  end

  view :with_issues do
    association :issues, blueprint: IssueSerializer
  end
end
