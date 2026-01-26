# frozen_string_literal: true

class Attachment < ApplicationRecord
  ATTACHMENT_TYPES = %w[github_pr github_issue url file].freeze

  belongs_to :issue

  validates :url, presence: true
  validates :attachment_type, inclusion: { in: ATTACHMENT_TYPES }, allow_nil: true

  scope :github_prs, -> { where(attachment_type: "github_pr") }
  scope :urls, -> { where(attachment_type: "url") }
  scope :files, -> { where(attachment_type: "file") }
  scope :ordered, -> { order(created_at: :desc) }

  # Auto-detect attachment type from URL
  before_validation :detect_attachment_type

  def github_pr?
    attachment_type == "github_pr"
  end

  def github_issue?
    attachment_type == "github_issue"
  end

  def file?
    attachment_type == "file"
  end

  private

  def detect_attachment_type
    return if attachment_type.present? || url.blank?

    if url.match?(%r{github\.com/.+/pull/\d+})
      self.attachment_type = "github_pr"
    elsif url.match?(%r{github\.com/.+/issues/\d+})
      self.attachment_type = "github_issue"
    else
      self.attachment_type = "url"
    end
  end
end
