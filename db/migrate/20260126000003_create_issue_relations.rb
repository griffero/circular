# frozen_string_literal: true

class CreateIssueRelations < ActiveRecord::Migration[8.0]
  def change
    create_table :issue_relations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :issue, type: :uuid, null: false, foreign_key: true
      t.references :related_issue, type: :uuid, null: false, foreign_key: { to_table: :issues }
      t.string :relation_type, null: false # blocks, related, duplicate
      t.string :linear_id

      t.timestamps
    end

    add_index :issue_relations, [:issue_id, :related_issue_id, :relation_type],
              unique: true,
              name: "idx_unique_issue_relations"
    add_index :issue_relations, :linear_id, unique: true, where: "linear_id IS NOT NULL"
    add_index :issue_relations, :relation_type
  end
end
