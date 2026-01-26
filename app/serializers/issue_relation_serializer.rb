# frozen_string_literal: true

class IssueRelationSerializer < Blueprinter::Base
  identifier :id

  fields :relation_type, :created_at, :updated_at

  field :issue_id do |relation|
    relation.issue_id
  end

  field :related_issue_id do |relation|
    relation.related_issue_id
  end

  view :with_issues do
    association :issue, blueprint: IssueSerializer
    association :related_issue, blueprint: IssueSerializer
  end
end
