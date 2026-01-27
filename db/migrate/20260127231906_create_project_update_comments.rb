class CreateProjectUpdateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :project_update_comments, id: :uuid do |t|
      t.references :project_update, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.text :body
      t.string :linear_id

      t.timestamps
    end
    
    add_index :project_update_comments, :linear_id, unique: true
  end
end
