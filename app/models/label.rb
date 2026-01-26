# frozen_string_literal: true

class Label < ApplicationRecord
  belongs_to :team, optional: true
  belongs_to :parent, class_name: "Label", optional: true

  has_many :issue_labels, dependent: :destroy
  has_many :issues, through: :issue_labels
  has_many :children, class_name: "Label", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent

  validates :name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color" }

  # Global labels (team_id nil) are available to all teams
  scope :global, -> { where(team_id: nil) }
  scope :for_team, ->(team_id) { where(team_id: [team_id, nil]) }
  scope :ordered, -> { order(:name) }
  scope :groups, -> { where(is_group: true) }
  scope :not_groups, -> { where(is_group: false) }
  scope :top_level, -> { where(parent_id: nil) }

  def group?
    is_group
  end
end
