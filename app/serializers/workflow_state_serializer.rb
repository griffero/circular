# frozen_string_literal: true

class WorkflowStateSerializer < Blueprinter::Base
  identifier :id

  fields :name, :color, :description, :state_type, :position, :created_at, :updated_at

  field :team_id do |state|
    state.team_id
  end

  field :linear_id do |state|
    state.linear_id
  end

  view :with_team do
    association :team, blueprint: TeamSerializer
  end
end
