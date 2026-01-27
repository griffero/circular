# frozen_string_literal: true

class CreateProjectUpdates < ActiveRecord::Migration[8.0]
  def change
    create_table :project_updates, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.text :body, null: false
      t.text :body_html
      t.string :health # onTrack, atRisk, offTrack
      t.string :linear_id
      t.datetime :edited_at

      t.timestamps
    end

    add_index :project_updates, :linear_id, unique: true, where: "linear_id IS NOT NULL"
    add_index :project_updates, [:project_id, :created_at]
  end
end
