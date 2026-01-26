# frozen_string_literal: true

class IssueSerializer < Blueprinter::Base
  identifier :id

  fields :identifier, :number, :title, :description, :status, :priority,
         :due_date, :estimate, :sort_order, :started_at, :completed_at,
         :canceled_at, :archived_at, :created_at, :updated_at

  field :team_id do |issue|
    issue.team_id
  end

  field :creator_id do |issue|
    issue.creator_id
  end

  field :assignee_id do |issue|
    issue.assignee_id
  end

  field :project_id do |issue|
    issue.project_id
  end

  field :parent_id do |issue|
    issue.parent_id
  end

  field :priority_label do |issue|
    issue.priority_label
  end

  view :with_creator do
    association :creator, blueprint: UserSerializer
  end

  view :with_assignee do
    association :assignee, blueprint: UserSerializer
  end

  view :with_team do
    association :team, blueprint: TeamSerializer
  end

  view :with_project do
    association :project, blueprint: ProjectSerializer
  end

  view :with_labels do
    association :labels, blueprint: LabelSerializer
  end

  view :list do
    include_view :with_creator
    include_view :with_assignee
    include_view :with_labels
  end

  view :detailed do
    include_view :with_creator
    include_view :with_assignee
    include_view :with_team
    include_view :with_project
    include_view :with_labels
    association :sub_issues, blueprint: IssueSerializer
    association :parent, blueprint: IssueSerializer
  end
end
