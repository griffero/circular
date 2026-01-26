# frozen_string_literal: true

class AddLinearFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    # Add health tracking (onTrack, atRisk, offTrack)
    add_column :projects, :health, :string

    # Add progress percentage
    add_column :projects, :progress, :float, default: 0

    # Add linear_id for sync mapping
    add_column :projects, :linear_id, :string
    add_index :projects, :linear_id, unique: true, where: "linear_id IS NOT NULL"

    # Add slug_id (Linear uses this)
    add_column :projects, :slug_id, :string
    add_index :projects, :slug_id, unique: true, where: "slug_id IS NOT NULL"

    # Add state column to match Linear's project states
    # (backlog, planned, started, paused, completed, canceled)
    # This is different from existing 'status' which is (active, paused, completed, canceled)
    add_column :projects, :state, :string, default: "backlog"
    add_index :projects, :state
  end
end
