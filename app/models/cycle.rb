# frozen_string_literal: true

class Cycle < ApplicationRecord
  belongs_to :team
  has_many :issues, dependent: :nullify

  validates :number, presence: true, uniqueness: { scope: :team_id }

  scope :ordered, -> { order(starts_at: :desc) }
  scope :active, -> { where("starts_at <= ? AND ends_at >= ?", Time.current, Time.current) }
  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :past, -> { where("ends_at < ?", Time.current).order(ends_at: :desc) }
  scope :current, -> { active.first }

  def active?
    return false unless starts_at && ends_at

    Time.current.between?(starts_at, ends_at)
  end

  def upcoming?
    return false unless starts_at

    starts_at > Time.current
  end

  def completed?
    completed_at.present?
  end

  def past?
    return false unless ends_at

    ends_at < Time.current
  end

  def duration_in_days
    return nil unless starts_at && ends_at

    ((ends_at - starts_at) / 1.day).round
  end

  def display_name
    name.presence || "Cycle #{number}"
  end

  def calculate_progress
    return 0 if issues.count.zero?

    completed_count = issues.joins(:workflow_state)
                            .where(workflow_states: { state_type: %w[completed canceled] })
                            .count
    (completed_count.to_f / issues.count * 100).round(2)
  end
end
