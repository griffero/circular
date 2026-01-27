# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Issues - compound index for default sorting
    add_index :issues, [:team_id, :sort_order, :created_at],
              name: "index_issues_on_team_sort_created",
              algorithm: :concurrently,
              if_not_exists: true

    # Issues - updated_at for sorting
    add_index :issues, :updated_at,
              algorithm: :concurrently,
              if_not_exists: true

    # Issues - compound index for cycle issues list
    add_index :issues, [:cycle_id, :workflow_state_id],
              name: "index_issues_on_cycle_and_state",
              algorithm: :concurrently,
              if_not_exists: true

    # Projects - compound index for filtering
    add_index :projects, [:status, :created_at],
              name: "index_projects_on_status_and_created",
              algorithm: :concurrently,
              if_not_exists: true

    # Comments - for counting and loading
    add_index :comments, [:issue_id, :user_id],
              name: "index_comments_on_issue_and_user",
              algorithm: :concurrently,
              if_not_exists: true

    # Sync logs - for cleanup (delete old logs)
    add_index :sync_logs, :processed_at,
              algorithm: :concurrently,
              if_not_exists: true

    # Users - for active user filtering
    add_index :users, [:active, :role],
              name: "index_users_on_active_and_role",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
