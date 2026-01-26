# frozen_string_literal: true

class LabelSerializer < Blueprinter::Base
  identifier :id

  fields :name, :color, :description, :is_group, :created_at, :updated_at

  field :team_id do |label|
    label.team_id
  end

  field :parent_id do |label|
    label.parent_id
  end

  field :linear_id do |label|
    label.linear_id
  end

  view :with_parent do
    association :parent, blueprint: LabelSerializer
  end

  view :with_children do
    association :children, blueprint: LabelSerializer
  end

  view :detailed do
    include_view :with_parent
    include_view :with_children
  end
end
