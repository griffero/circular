# frozen_string_literal: true

class AddLinearFieldsToIssues < ActiveRecord::Migration[8.0]
  def change
    # Add workflow_state reference (will eventually replace status column)
    add_reference :issues, :workflow_state, type: :uuid, foreign_key: { to_table: :workflow_states }

    # Add cycle reference
    add_reference :issues, :cycle, type: :uuid, foreign_key: true

    # Add linear_id for sync mapping
    add_column :issues, :linear_id, :string
    add_index :issues, :linear_id, unique: true, where: "linear_id IS NOT NULL"

    # Add index for workflow_state queries
    add_index :issues, [:team_id, :workflow_state_id], name: "index_issues_on_team_id_and_workflow_state_id"
    add_index :issues, [:assignee_id, :workflow_state_id], name: "index_issues_on_assignee_id_and_workflow_state_id"
    add_index :issues, [:project_id, :workflow_state_id], name: "index_issues_on_project_id_and_workflow_state_id"
  end
end
