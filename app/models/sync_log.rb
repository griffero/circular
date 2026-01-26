# frozen_string_literal: true

class SyncLog < ApplicationRecord
  ENTITY_TYPES = %w[
    Issue Project User Team WorkflowState Cycle
    Label IssueLabel Comment Attachment IssueRelation
  ].freeze

  ACTIONS = %w[create update delete].freeze
  SOURCES = %w[webhook polling manual].freeze
  STATUSES = %w[pending processed failed].freeze

  validates :entity_type, presence: true, inclusion: { in: ENTITY_TYPES }
  validates :linear_id, presence: true
  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :processed, -> { where(status: "processed") }
  scope :failed, -> { where(status: "failed") }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_entity, ->(type, linear_id) { where(entity_type: type, linear_id: linear_id) }

  # Alias for the renamed column (change_data instead of changes to avoid AR conflict)
  alias_attribute :changes_data, :change_data

  def mark_processed!
    update!(status: "processed", processed_at: Time.current)
  end

  def mark_failed!(error)
    update!(status: "failed", error_message: error.to_s, processed_at: Time.current)
  end

  def pending?
    status == "pending"
  end

  def processed?
    status == "processed"
  end

  def failed?
    status == "failed"
  end
end
