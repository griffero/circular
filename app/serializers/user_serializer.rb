# frozen_string_literal: true

class UserSerializer < Blueprinter::Base
  identifier :id

  fields :email, :name, :display_name, :avatar_url, :timezone, :role,
         :admin, :guest, :active, :created_at, :updated_at

  field :linear_id do |user|
    user.linear_id
  end

  view :with_teams do
    association :teams, blueprint: TeamSerializer, view: :minimal
  end

  view :detailed do
    include_view :with_teams
    association :projects, blueprint: ProjectSerializer, view: :minimal
  end
end
