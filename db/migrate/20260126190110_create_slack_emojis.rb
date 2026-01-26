class CreateSlackEmojis < ActiveRecord::Migration[8.0]
  def change
    create_table :slack_emojis, id: :uuid do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :alias_for

      t.timestamps
    end
    add_index :slack_emojis, :name, unique: true
  end
end
