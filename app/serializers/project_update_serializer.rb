# frozen_string_literal: true

class ProjectUpdateSerializer < Blueprinter::Base
  identifier :id

  fields :body, :health, :edited_at, :created_at, :updated_at

  association :project, blueprint: ProjectSerializer
  association :user, blueprint: UserSerializer
end
