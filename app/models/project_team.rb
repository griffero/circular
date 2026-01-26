# frozen_string_literal: true

class ProjectTeam < ApplicationRecord
  belongs_to :project
  belongs_to :team

  validates :project_id, uniqueness: { scope: :team_id }
end
