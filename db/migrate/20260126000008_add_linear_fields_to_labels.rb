# frozen_string_literal: true

class AddLinearFieldsToLabels < ActiveRecord::Migration[8.0]
  def change
    # Add parent reference for label groups (this creates index_labels_on_parent_id automatically)
    add_reference :labels, :parent, type: :uuid, foreign_key: { to_table: :labels }

    # Add is_group flag
    add_column :labels, :is_group, :boolean, default: false, null: false

    # Add linear_id for sync mapping
    add_column :labels, :linear_id, :string
    add_index :labels, :linear_id, unique: true, where: "linear_id IS NOT NULL"
  end
end
