# frozen_string_literal: true

class CreateProjectTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :project_teams, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :project, type: :uuid, null: false, foreign_key: true
      t.references :team, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end

    add_index :project_teams, [:project_id, :team_id], unique: true
  end
end
