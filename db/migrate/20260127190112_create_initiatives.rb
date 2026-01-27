# frozen_string_literal: true

class CreateInitiatives < ActiveRecord::Migration[8.0]
  def change
    create_table :initiatives, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :icon
      t.string :color
      t.references :owner, type: :uuid, foreign_key: { to_table: :users }
      t.string :status, default: "backlog" # backlog, planned, started, paused, completed, canceled
      t.string :health # onTrack, atRisk, offTrack
      t.integer :target_year
      t.integer :target_quarter # 1, 2, 3, 4
      t.date :target_date
      t.integer :sort_order, default: 0
      t.string :linear_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :slug, unique: true
      t.index :status
      t.index :linear_id, unique: true, where: "linear_id IS NOT NULL"
      # owner_id index is created automatically by t.references :owner
    end

    # Join table for initiatives and projects
    create_table :initiative_projects, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :initiative, type: :uuid, null: false, foreign_key: true
      t.references :project, type: :uuid, null: false, foreign_key: true
      t.integer :sort_order, default: 0
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [:initiative_id, :project_id], unique: true
    end
  end
end
