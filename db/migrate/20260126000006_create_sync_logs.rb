# frozen_string_literal: true

class CreateSyncLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :sync_logs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :entity_type, null: false # Issue, Project, User, etc.
      t.string :linear_id, null: false
      t.string :action, null: false # create, update, delete
      t.string :source, null: false # webhook, polling, manual
      t.jsonb :payload
      t.jsonb :changes
      t.string :status, default: "pending" # pending, processed, failed
      t.text :error_message
      t.datetime :processed_at

      t.timestamps
    end

    add_index :sync_logs, [:entity_type, :linear_id]
    add_index :sync_logs, [:status, :created_at]
    add_index :sync_logs, :created_at
  end
end
