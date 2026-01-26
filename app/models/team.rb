# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :team_memberships, dependent: :destroy
  has_many :members, through: :team_memberships, source: :user
  has_many :issues, dependent: :destroy
  has_many :labels, dependent: :destroy
  has_many :workflow_states, dependent: :destroy
  has_many :cycles, dependent: :destroy
  has_many :project_teams, dependent: :destroy
  has_many :projects, through: :project_teams

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :key, presence: true,
                  length: { minimum: 2, maximum: 10 },
                  format: { with: /\A[A-Z][A-Z0-9]*\z/, message: "must be uppercase letters and numbers, starting with a letter" },
                  uniqueness: { message: "is already taken" }

  before_validation :upcase_key

  scope :ordered, -> { order(:name) }

  # Get next issue number for this team (with lock for concurrency)
  def next_issue_number!
    with_lock do
      update_column(:issue_counter, issue_counter + 1)
      issue_counter
    end
  end

  alias_method :next_issue_number, :next_issue_number!

  # Generate issue identifier like "ENG-123"
  def issue_identifier(number)
    "#{key}-#{number}"
  end

  private

  def upcase_key
    self.key = key.to_s.upcase if key.present?
  end
end
