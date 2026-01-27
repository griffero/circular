# frozen_string_literal: true

class Initiative < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: "User", optional: true
  has_many :initiative_projects, dependent: :destroy
  has_many :projects, through: :initiative_projects

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Scopes - wrapped in lambdas to defer evaluation
  scope :ordered, -> { order(sort_order: :asc, created_at: :desc) }
  scope :active, -> { where(status: "started") }
  scope :planned, -> { where(status: "planned") }
  scope :completed, -> { where(status: "completed") }
  scope :by_status, ->(status) { status.present? ? where(status: status) : all }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Status constants
  STATUSES = %w[backlog planned started paused completed canceled].freeze

  # Health constants
  HEALTHS = %w[onTrack atRisk offTrack].freeze

  # Calculate target display (e.g., "Q4 2025")
  def target_display
    return nil unless target_year

    if target_quarter
      "Q#{target_quarter} #{target_year}"
    else
      target_year.to_s
    end
  end

  # Calculate projects progress (completed / total)
  def projects_progress
    total = projects.count
    return { completed: 0, total: 0 } if total.zero?

    completed = projects.where(state: "completed").count
    { completed: completed, total: total }
  end

  # Find by Linear ID
  def self.find_by_linear_id(linear_id)
    find_by(linear_id: linear_id)
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = name.parameterize
    self.slug = base_slug

    counter = 1
    while Initiative.exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
