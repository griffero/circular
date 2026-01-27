# frozen_string_literal: true

class InitiativeProject < ApplicationRecord
  belongs_to :initiative
  belongs_to :project

  validates :initiative_id, uniqueness: { scope: :project_id }

  scope :ordered, -> { order(sort_order: :asc) }
end
