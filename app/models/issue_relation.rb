# frozen_string_literal: true

class IssueRelation < ApplicationRecord
  RELATION_TYPES = %w[blocks related duplicate].freeze

  belongs_to :issue
  belongs_to :related_issue, class_name: "Issue"

  validates :relation_type, presence: true, inclusion: { in: RELATION_TYPES }
  validates :issue_id, uniqueness: { scope: [ :related_issue_id, :relation_type ] }

  # Prevent self-referencing relations
  validate :not_self_referencing

  scope :blocks, -> { where(relation_type: "blocks") }
  scope :related, -> { where(relation_type: "related") }
  scope :duplicates, -> { where(relation_type: "duplicate") }

  # Get the inverse relation type
  def inverse_relation_type
    case relation_type
    when "blocks"
      "blocked_by"
    when "duplicate"
      "duplicate_of"
    else
      relation_type
    end
  end

  # Create inverse relation for bidirectional relationships
  def create_inverse!
    return if relation_type == "blocks" # blocks is directional

    IssueRelation.find_or_create_by!(
      issue: related_issue,
      related_issue: issue,
      relation_type: relation_type
    )
  end

  private

  def not_self_referencing
    if issue_id == related_issue_id
      errors.add(:related_issue, "cannot be the same as the issue")
    end
  end
end
