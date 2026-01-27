# frozen_string_literal: true

class ProjectUpdateCommentSerializer < Blueprinter::Base
  identifier :id

  fields :body, :created_at, :updated_at

  field :project_update_id do |comment|
    comment.project_update_id
  end

  field :user_id do |comment|
    comment.user_id
  end

  association :user, blueprint: UserSerializer, view: :minimal
end
