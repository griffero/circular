# frozen_string_literal: true

class AttachmentSerializer < Blueprinter::Base
  identifier :id

  fields :title, :url, :attachment_type, :created_at, :updated_at

  field :issue_id do |attachment|
    attachment.issue_id
  end

  field :linear_id do |attachment|
    attachment.linear_id
  end
end
