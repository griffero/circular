# frozen_string_literal: true

class RenameChangesColumnInSyncLogs < ActiveRecord::Migration[8.0]
  def change
    rename_column :sync_logs, :changes, :change_data
  end
end
