# frozen_string_literal: true

class ProjectUpdateSerializer < Blueprinter::Base
  identifier :id

  fields :body, :health, :edited_at, :created_at, :updated_at

  field :comments_count do |update|
    update.comments.count
  end

  association :project, blueprint: ProjectSerializer
  association :user, blueprint: UserSerializer

  view :with_comments do
    include_view :default
    association :comments, blueprint: ProjectUpdateCommentSerializer
  end
end
