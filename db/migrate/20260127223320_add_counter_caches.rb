# frozen_string_literal: true

class AddCounterCaches < ActiveRecord::Migration[8.0]
  def change
    # Project issues count
    add_column :projects, :issues_count, :integer, default: 0, null: false

    # Team issues count
    add_column :teams, :issues_count, :integer, default: 0, null: false

    # Issue comments count
    add_column :issues, :comments_count, :integer, default: 0, null: false

    # Issue sub_issues count (children count)
    add_column :issues, :sub_issues_count, :integer, default: 0, null: false

    # Reset counters (run in background for large datasets)
    reversible do |dir|
      dir.up do
        # These will be populated by a rake task after migration
        say "Counter caches added. Run 'rails counters:reset' to populate them."
      end
    end
  end
end
