# frozen_string_literal: true

class WorkflowState < ApplicationRecord
  # State types match Linear's workflow state types
  STATE_TYPES = %w[triage backlog unstarted started completed canceled].freeze

  belongs_to :team
  has_many :issues, dependent: :nullify

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :name, uniqueness: { scope: :team_id }
  validates :color, presence: true
  validates :state_type, presence: true, inclusion: { in: STATE_TYPES }

  scope :ordered, -> { order(:position) }
  scope :by_type, ->(type) { where(state_type: type) }
  scope :active, -> { where.not(state_type: %w[completed canceled]) }

  # Type helpers
  def triage?
    state_type == "triage"
  end

  def backlog?
    state_type == "backlog"
  end

  def unstarted?
    state_type == "unstarted"
  end

  def started?
    state_type == "started"
  end

  def completed?
    state_type == "completed"
  end

  def canceled?
    state_type == "canceled"
  end

  # Map Linear state type to legacy status for backwards compatibility
  def legacy_status
    case state_type
    when "triage", "backlog"
      "backlog"
    when "unstarted"
      "todo"
    when "started"
      "in_progress"
    when "completed"
      "done"
    when "canceled"
      "canceled"
    else
      "backlog"
    end
  end
end
