# frozen_string_literal: true

class ProjectUpdateComment < ApplicationRecord
  belongs_to :project_update
  belongs_to :user

  validates :body, presence: true

  scope :recent, -> { order(created_at: :asc) }
  scope :by_linear_id, ->(linear_id) { where(linear_id: linear_id) }
end
