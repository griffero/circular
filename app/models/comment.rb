# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :issue, counter_cache: true
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true

  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy

  validates :body, presence: true, length: { minimum: 1, maximum: 100_000 }

  after_create :record_activity

  scope :top_level, -> { where(parent_id: nil) }
  scope :ordered, -> { order(created_at: :asc) }

  def edited?
    edited_at.present?
  end

  def edit!(new_body)
    update!(body: new_body, edited_at: Time.current)
  end

  private

  def record_activity
    IssueActivity.create!(
      issue: issue,
      user: user,
      action: "commented"
    )
  end
end
