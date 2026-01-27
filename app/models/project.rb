# frozen_string_literal: true

class Project < ApplicationRecord
  STATUSES = %w[active paused completed canceled].freeze
  PRIVACIES = %w[public private].freeze
  # Linear project states
  STATES = %w[backlog planned started paused completed canceled].freeze
  HEALTH_VALUES = %w[onTrack atRisk offTrack].freeze

  belongs_to :lead, class_name: "User", optional: true
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user
  has_many :issues, dependent: :nullify
  has_many :project_teams, dependent: :destroy
  has_many :teams, through: :project_teams
  has_many :project_updates, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true,
                   length: { minimum: 2, maximum: 50 },
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "must be lowercase with hyphens only" },
                   uniqueness: { message: "is already taken" }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :privacy, presence: true, inclusion: { in: PRIVACIES }
  validates :state, inclusion: { in: STATES }, allow_nil: true
  validates :health, inclusion: { in: HEALTH_VALUES }, allow_nil: true

  before_validation :generate_slug, on: :create

  scope :active, -> { where(status: "active") }
  scope :public_projects, -> { where(privacy: "public") }
  # Order by state priority (started first), then by start_date, then by name
  scope :ordered, lambda {
    order(
      Arel.sql("CASE state WHEN 'started' THEN 1 WHEN 'planned' THEN 2 WHEN 'paused' THEN 3 WHEN 'backlog' THEN 4 WHEN 'completed' THEN 5 WHEN 'canceled' THEN 6 ELSE 7 END"),
      Arel.sql("start_date ASC NULLS LAST"),
      :name
    )
  }

  def active?
    status == "active"
  end

  def public?
    privacy == "public"
  end

  def private?
    privacy == "private"
  end

  # Linear state helpers
  def started?
    state == "started"
  end

  def planned?
    state == "planned"
  end

  # Health helpers
  def on_track?
    health == "onTrack"
  end

  def at_risk?
    health == "atRisk"
  end

  def off_track?
    health == "offTrack"
  end

  # Calculate progress based on issues
  def calculate_progress
    return 0 if issues.count.zero?

    completed_count = issues.joins(:workflow_state)
                            .where(workflow_states: { state_type: %w[completed canceled] })
                            .count
    (completed_count.to_f / issues.count * 100).round(2)
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = name.to_s.parameterize
    self.slug = base_slug

    counter = 1
    while Project.where(slug: slug).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
