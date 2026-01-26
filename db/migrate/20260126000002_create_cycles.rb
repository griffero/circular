# frozen_string_literal: true

class CreateCycles < ActiveRecord::Migration[8.0]
  def change
    create_table :cycles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :team, type: :uuid, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :name
      t.text :description
      t.datetime :starts_at
      t.datetime :ends_at
      t.float :progress, default: 0
      t.datetime :completed_at
      t.string :linear_id

      t.timestamps
    end

    add_index :cycles, [:team_id, :number], unique: true
    add_index :cycles, :linear_id, unique: true, where: "linear_id IS NOT NULL"
    add_index :cycles, [:team_id, :starts_at]
    add_index :cycles, [:team_id, :ends_at]
  end
end
