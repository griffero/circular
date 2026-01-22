# frozen_string_literal: true

class ConvertToSingleTenant < ActiveRecord::Migration[8.0]
  def up
    # 1. Add role to users (if not exists)
    unless column_exists?(:users, :role)
      add_column :users, :role, :string, default: 'member', null: false
    end
    unless index_exists?(:users, :role)
      add_index :users, :role
    end

    # 2. Remove workspace_id from teams (make key globally unique)
    if index_exists?(:teams, [:workspace_id, :key])
      remove_index :teams, [:workspace_id, :key]
    end
    if foreign_key_exists?(:teams, :workspaces)
      remove_foreign_key :teams, :workspaces
    end
    if column_exists?(:teams, :workspace_id)
      remove_column :teams, :workspace_id
    end
    unless index_exists?(:teams, :key, unique: true)
      add_index :teams, :key, unique: true
    end

    # 3. Remove workspace_id from projects (make slug globally unique)
    if index_exists?(:projects, [:workspace_id, :slug])
      remove_index :projects, [:workspace_id, :slug]
    end
    if index_exists?(:projects, :workspace_id)
      remove_index :projects, :workspace_id
    end
    if foreign_key_exists?(:projects, :workspaces)
      remove_foreign_key :projects, :workspaces
    end
    if column_exists?(:projects, :workspace_id)
      remove_column :projects, :workspace_id
    end
    unless index_exists?(:projects, :slug, unique: true)
      add_index :projects, :slug, unique: true
    end

    # 4. Remove workspace_id from labels
    if index_exists?(:labels, [:workspace_id, :name])
      remove_index :labels, [:workspace_id, :name]
    end
    if index_exists?(:labels, :workspace_id)
      remove_index :labels, :workspace_id
    end
    if foreign_key_exists?(:labels, :workspaces)
      remove_foreign_key :labels, :workspaces
    end
    if column_exists?(:labels, :workspace_id)
      remove_column :labels, :workspace_id
    end
    # Add unique constraint for global labels (team_id can be null for global)
    unless index_exists?(:labels, [:team_id, :name], name: "index_labels_on_team_id_and_name_unique")
      add_index :labels, [:team_id, :name], unique: true, where: "team_id IS NOT NULL", name: "index_labels_on_team_id_and_name_unique"
    end
    unless index_exists?(:labels, :name, name: "index_global_labels_on_name_unique")
      add_index :labels, :name, unique: true, where: "team_id IS NULL", name: "index_global_labels_on_name_unique"
    end

    # 5. Remove workspace_id from issues
    if index_exists?(:issues, [:workspace_id, :status])
      remove_index :issues, [:workspace_id, :status]
    end
    if index_exists?(:issues, :workspace_id)
      remove_index :issues, :workspace_id
    end
    if foreign_key_exists?(:issues, :workspaces)
      remove_foreign_key :issues, :workspaces
    end
    if column_exists?(:issues, :workspace_id)
      remove_column :issues, :workspace_id
    end

    # 6. Drop workspace_memberships table
    drop_table :workspace_memberships if table_exists?(:workspace_memberships)

    # 7. Drop workspaces table
    drop_table :workspaces if table_exists?(:workspaces)
  end

  def down
    # Recreate workspaces table
    create_table :workspaces, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :logo_url
      t.jsonb :settings, default: {}
      t.timestamps
    end
    add_index :workspaces, :slug, unique: true

    # Recreate workspace_memberships table
    create_table :workspace_memberships, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.uuid :workspace_id, null: false
      t.string :role, default: 'member', null: false
      t.timestamps
    end
    add_index :workspace_memberships, [:user_id, :workspace_id], unique: true
    add_index :workspace_memberships, :user_id
    add_index :workspace_memberships, :workspace_id
    add_index :workspace_memberships, :role
    add_foreign_key :workspace_memberships, :users
    add_foreign_key :workspace_memberships, :workspaces

    # Note: Data migration back would need to be handled separately
    # This just recreates the structure

    # Add workspace_id back to issues
    add_column :issues, :workspace_id, :uuid
    add_index :issues, :workspace_id
    add_index :issues, [:workspace_id, :status]

    # Add workspace_id back to labels
    remove_index :labels, name: "index_labels_on_team_id_and_name_unique"
    remove_index :labels, name: "index_global_labels_on_name_unique"
    add_column :labels, :workspace_id, :uuid
    add_index :labels, :workspace_id
    add_index :labels, [:workspace_id, :name]

    # Add workspace_id back to projects
    remove_index :projects, :slug
    add_column :projects, :workspace_id, :uuid
    add_index :projects, :workspace_id
    add_index :projects, [:workspace_id, :slug], unique: true

    # Add workspace_id back to teams
    remove_index :teams, :key
    add_column :teams, :workspace_id, :uuid
    add_index :teams, [:workspace_id, :key], unique: true

    # Remove role from users
    remove_index :users, :role
    remove_column :users, :role
  end
end
