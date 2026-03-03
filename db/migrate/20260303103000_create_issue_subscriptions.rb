# frozen_string_literal: true

class CreateIssueSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :issue_subscriptions, id: :uuid do |t|
      t.references :issue, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :issue_subscriptions, %i[issue_id user_id], unique: true
  end
end
