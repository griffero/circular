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
  after_create :seed_default_workflow_states, if: :circular_native?

  scope :ordered, -> { order(:name) }

  DEFAULT_WORKFLOW_STATES = [
    { name: "Triage",      state_type: "triage",    color: "#95a2b3", position: 0 },
    { name: "Backlog",     state_type: "backlog",   color: "#bec2c8", position: 1 },
    { name: "Todo",        state_type: "unstarted", color: "#e2e2e2", position: 2 },
    { name: "In Progress", state_type: "started",   color: "#f2c94c", position: 3 },
    { name: "Done",        state_type: "completed", color: "#4cb782", position: 4 },
    { name: "Canceled",    state_type: "canceled",  color: "#95a2b3", position: 5 }
  ].freeze

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

  def seed_default_workflow_states
    DEFAULT_WORKFLOW_STATES.each do |attrs|
      workflow_states.create!(attrs)
    end
  end
end
