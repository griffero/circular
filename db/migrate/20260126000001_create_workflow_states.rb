# frozen_string_literal: true

class CreateWorkflowStates < ActiveRecord::Migration[8.0]
  def change
    create_table :workflow_states, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :team, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false
      t.string :description
      t.string :state_type, null: false # triage, backlog, unstarted, started, completed, canceled
      t.float :position, default: 0
      t.string :linear_id

      t.timestamps
    end

    add_index :workflow_states, [:team_id, :name], unique: true
    add_index :workflow_states, :linear_id, unique: true, where: "linear_id IS NOT NULL"
    add_index :workflow_states, [:team_id, :state_type]
    add_index :workflow_states, [:team_id, :position]
  end
end
