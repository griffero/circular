# frozen_string_literal: true

class CreateAttachments < ActiveRecord::Migration[8.0]
  def change
    create_table :attachments, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :issue, type: :uuid, null: false, foreign_key: true
      t.string :title
      t.string :url, null: false
      t.string :attachment_type # github_pr, url, file
      t.string :linear_id

      t.timestamps
    end

    add_index :attachments, :linear_id, unique: true, where: "linear_id IS NOT NULL"
    add_index :attachments, :attachment_type
  end
end
