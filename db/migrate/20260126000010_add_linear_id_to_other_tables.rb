# frozen_string_literal: true

class AddLinearIdToOtherTables < ActiveRecord::Migration[8.0]
  def change
    # Add linear_id to teams
    add_column :teams, :linear_id, :string
    add_index :teams, :linear_id, unique: true, where: "linear_id IS NOT NULL"

    # Add linear_id to users
    add_column :users, :linear_id, :string
    add_index :users, :linear_id, unique: true, where: "linear_id IS NOT NULL"

    # Add display_name to users (Linear has this)
    add_column :users, :display_name, :string

    # Add admin and guest flags to users
    add_column :users, :admin, :boolean, default: false, null: false
    add_column :users, :guest, :boolean, default: false, null: false
    add_column :users, :active, :boolean, default: true, null: false

    # Add linear_id to comments
    add_column :comments, :linear_id, :string
    add_index :comments, :linear_id, unique: true, where: "linear_id IS NOT NULL"

    # Add linear_id to issue_labels for sync
    add_column :issue_labels, :linear_id, :string
    add_index :issue_labels, :linear_id, unique: true, where: "linear_id IS NOT NULL"
  end
end
