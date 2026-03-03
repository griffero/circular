# frozen_string_literal: true

class IssueSubscription < ApplicationRecord
  belongs_to :issue
  belongs_to :user

  validates :user_id, uniqueness: { scope: :issue_id }
end
