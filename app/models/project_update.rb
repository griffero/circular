# frozen_string_literal: true

class ProjectUpdate < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_linear_id, ->(linear_id) { where(linear_id: linear_id) }
end
