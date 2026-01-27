# frozen_string_literal: true

class TeamSerializer < Blueprinter::Base
  identifier :id

  fields :name, :key, :description, :icon, :color, :issue_counter, :created_at, :updated_at

  field :linear_id do |team|
    team.linear_id
  end

  view :minimal do
    fields :id, :name, :key, :icon, :color
  end

  view :with_members do
    association :members, blueprint: UserSerializer
  end

  view :with_workflow_states do
    association :workflow_states, blueprint: WorkflowStateSerializer
  end

  view :with_cycles do
    association :cycles, blueprint: CycleSerializer
  end

  view :detailed do
    include_view :with_members
    include_view :with_workflow_states
    field :settings
  end
end
