# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_27_190112) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "issue_id", null: false
    t.string "title"
    t.string "url", null: false
    t.string "attachment_type"
    t.string "linear_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attachment_type"], name: "index_attachments_on_attachment_type"
    t.index ["issue_id"], name: "index_attachments_on_issue_id"
    t.index ["linear_id"], name: "index_attachments_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
  end

  create_table "comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "issue_id", null: false
    t.uuid "user_id", null: false
    t.uuid "parent_id"
    t.text "body", null: false
    t.text "body_html"
    t.datetime "edited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "linear_id"
    t.index ["issue_id", "created_at"], name: "index_comments_on_issue_id_and_created_at"
    t.index ["issue_id"], name: "index_comments_on_issue_id"
    t.index ["linear_id"], name: "index_comments_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "cycles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.integer "number", null: false
    t.string "name"
    t.text "description"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.float "progress", default: 0.0
    t.datetime "completed_at"
    t.string "linear_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linear_id"], name: "index_cycles_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
    t.index ["team_id", "ends_at"], name: "index_cycles_on_team_id_and_ends_at"
    t.index ["team_id", "number"], name: "index_cycles_on_team_id_and_number", unique: true
    t.index ["team_id", "starts_at"], name: "index_cycles_on_team_id_and_starts_at"
    t.index ["team_id"], name: "index_cycles_on_team_id"
  end

  create_table "initiative_projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "initiative_id", null: false
    t.uuid "project_id", null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["initiative_id", "project_id"], name: "index_initiative_projects_on_initiative_id_and_project_id", unique: true
    t.index ["initiative_id"], name: "index_initiative_projects_on_initiative_id"
    t.index ["project_id"], name: "index_initiative_projects_on_project_id"
  end

  create_table "initiatives", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "icon"
    t.string "color"
    t.uuid "owner_id"
    t.string "status", default: "backlog"
    t.string "health"
    t.integer "target_year"
    t.integer "target_quarter"
    t.date "target_date"
    t.integer "sort_order", default: 0
    t.string "linear_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linear_id"], name: "index_initiatives_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
    t.index ["owner_id"], name: "index_initiatives_on_owner_id"
    t.index ["slug"], name: "index_initiatives_on_slug", unique: true
    t.index ["status"], name: "index_initiatives_on_status"
  end

  create_table "issue_activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "issue_id", null: false
    t.uuid "user_id", null: false
    t.string "action", null: false
    t.string "field"
    t.text "old_value"
    t.text "new_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id", "created_at"], name: "index_issue_activities_on_issue_id_and_created_at"
    t.index ["issue_id"], name: "index_issue_activities_on_issue_id"
    t.index ["user_id"], name: "index_issue_activities_on_user_id"
  end

  create_table "issue_labels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "issue_id", null: false
    t.uuid "label_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "linear_id"
    t.index ["issue_id", "label_id"], name: "index_issue_labels_on_issue_id_and_label_id", unique: true
    t.index ["issue_id"], name: "index_issue_labels_on_issue_id"
    t.index ["label_id"], name: "index_issue_labels_on_label_id"
    t.index ["linear_id"], name: "index_issue_labels_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
  end

  create_table "issue_relations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "issue_id", null: false
    t.uuid "related_issue_id", null: false
    t.string "relation_type", null: false
    t.string "linear_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id", "related_issue_id", "relation_type"], name: "idx_unique_issue_relations", unique: true
    t.index ["issue_id"], name: "index_issue_relations_on_issue_id"
    t.index ["linear_id"], name: "index_issue_relations_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
    t.index ["related_issue_id"], name: "index_issue_relations_on_related_issue_id"
    t.index ["relation_type"], name: "index_issue_relations_on_relation_type"
  end

  create_table "issues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.uuid "creator_id", null: false
    t.uuid "assignee_id"
    t.uuid "project_id"
    t.uuid "parent_id"
    t.string "identifier", null: false
    t.integer "number", null: false
    t.string "title", null: false
    t.text "description"
    t.text "description_html"
    t.string "status", default: "backlog", null: false
    t.integer "priority", default: 0, null: false
    t.date "due_date"
    t.decimal "estimate", precision: 10, scale: 2
    t.integer "sort_order", default: 0, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "canceled_at"
    t.datetime "archived_at"
    t.tsvector "search_vector"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "workflow_state_id"
    t.uuid "cycle_id"
    t.string "linear_id"
    t.index ["assignee_id", "status"], name: "index_issues_on_assignee_id_and_status"
    t.index ["assignee_id", "workflow_state_id"], name: "index_issues_on_assignee_id_and_workflow_state_id"
    t.index ["assignee_id"], name: "index_issues_on_assignee_id"
    t.index ["created_at"], name: "index_issues_on_created_at"
    t.index ["creator_id"], name: "index_issues_on_creator_id"
    t.index ["cycle_id"], name: "index_issues_on_cycle_id"
    t.index ["due_date"], name: "index_issues_on_due_date"
    t.index ["identifier"], name: "index_issues_on_identifier", unique: true
    t.index ["linear_id"], name: "index_issues_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
    t.index ["parent_id"], name: "index_issues_on_parent_id"
    t.index ["priority"], name: "index_issues_on_priority"
    t.index ["project_id", "status"], name: "index_issues_on_project_id_and_status"
    t.index ["project_id", "workflow_state_id"], name: "index_issues_on_project_id_and_workflow_state_id"
    t.index ["project_id"], name: "index_issues_on_project_id"
    t.index ["search_vector"], name: "index_issues_on_search_vector", using: :gin
    t.index ["sort_order"], name: "index_issues_on_sort_order"
    t.index ["status"], name: "index_issues_on_status"
    t.index ["team_id", "number"], name: "index_issues_on_team_id_and_number", unique: true
    t.index ["team_id", "status"], name: "index_issues_on_team_id_and_status"
    t.index ["team_id", "workflow_state_id"], name: "index_issues_on_team_id_and_workflow_state_id"
    t.index ["team_id"], name: "index_issues_on_team_id"
    t.index ["workflow_state_id"], name: "index_issues_on_workflow_state_id"
  end

  create_table "labels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id"
    t.string "name", null: false
    t.string "color", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "parent_id"
    t.boolean "is_group", default: false, null: false
    t.string "linear_id"
    t.index ["linear_id"], name: "index_labels_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
    t.index ["name"], name: "index_global_labels_on_name_unique", unique: true, where: "(team_id IS NULL)"
    t.index ["parent_id"], name: "index_labels_on_parent_id"
    t.index ["team_id", "name"], name: "index_labels_on_team_id_and_name"
    t.index ["team_id", "name"], name: "index_labels_on_team_id_and_name_unique", unique: true, where: "(team_id IS NOT NULL)"
    t.index ["team_id"], name: "index_labels_on_team_id"
  end

  create_table "project_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "project_id", null: false
    t.string "role", default: "member"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_memberships_on_project_id"
    t.index ["user_id", "project_id"], name: "index_project_memberships_on_user_id_and_project_id", unique: true
    t.index ["user_id"], name: "index_project_memberships_on_user_id"
  end

  create_table "project_teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id", null: false
    t.uuid "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "team_id"], name: "index_project_teams_on_project_id_and_team_id", unique: true
    t.index ["project_id"], name: "index_project_teams_on_project_id"
    t.index ["team_id"], name: "index_project_teams_on_team_id"
  end

  create_table "project_updates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id", null: false
    t.uuid "user_id", null: false
    t.text "body", null: false
    t.text "body_html"
    t.string "health"
    t.string "linear_id"
    t.datetime "edited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linear_id"], name: "index_project_updates_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
    t.index ["project_id", "created_at"], name: "index_project_updates_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_project_updates_on_project_id"
    t.index ["user_id"], name: "index_project_updates_on_user_id"
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "icon"
    t.string "color"
    t.uuid "lead_id"
    t.string "privacy", default: "public"
    t.string "status", default: "active"
    t.date "start_date"
    t.date "target_date"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "health"
    t.float "progress", default: 0.0
    t.string "linear_id"
    t.string "slug_id"
    t.string "state", default: "backlog"
    t.index ["lead_id"], name: "index_projects_on_lead_id"
    t.index ["linear_id"], name: "index_projects_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
    t.index ["slug"], name: "index_projects_on_slug", unique: true
    t.index ["slug_id"], name: "index_projects_on_slug_id", unique: true, where: "(slug_id IS NOT NULL)"
    t.index ["state"], name: "index_projects_on_state"
    t.index ["status"], name: "index_projects_on_status"
  end

  create_table "slack_emojis", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.string "alias_for"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_slack_emojis_on_name", unique: true
  end

  create_table "sync_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "entity_type", null: false
    t.string "linear_id", null: false
    t.string "action", null: false
    t.string "source", null: false
    t.jsonb "payload"
    t.jsonb "change_data"
    t.string "status", default: "pending"
    t.text "error_message"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_sync_logs_on_created_at"
    t.index ["entity_type", "linear_id"], name: "index_sync_logs_on_entity_type_and_linear_id"
    t.index ["status", "created_at"], name: "index_sync_logs_on_status_and_created_at"
  end

  create_table "team_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "team_id", null: false
    t.string "role", default: "member"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id", "team_id"], name: "index_team_memberships_on_user_id_and_team_id", unique: true
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "key", null: false
    t.text "description"
    t.string "icon"
    t.string "color"
    t.integer "issue_counter", default: 0
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "linear_id"
    t.index ["key"], name: "index_teams_on_key", unique: true
    t.index ["linear_id"], name: "index_teams_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.string "name", null: false
    t.string "avatar_url"
    t.string "timezone", default: "UTC"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "member", null: false
    t.string "magic_link_token"
    t.datetime "magic_link_sent_at"
    t.string "linear_id"
    t.string "display_name"
    t.boolean "admin", default: false, null: false
    t.boolean "guest", default: false, null: false
    t.boolean "active", default: true, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["linear_id"], name: "index_users_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
    t.index ["magic_link_token"], name: "index_users_on_magic_link_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "workflow_states", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.string "name", null: false
    t.string "color", null: false
    t.string "description"
    t.string "state_type", null: false
    t.float "position", default: 0.0
    t.string "linear_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linear_id"], name: "index_workflow_states_on_linear_id", unique: true, where: "(linear_id IS NOT NULL)"
    t.index ["team_id", "name"], name: "index_workflow_states_on_team_id_and_name", unique: true
    t.index ["team_id", "position"], name: "index_workflow_states_on_team_id_and_position"
    t.index ["team_id", "state_type"], name: "index_workflow_states_on_team_id_and_state_type"
    t.index ["team_id"], name: "index_workflow_states_on_team_id"
  end

  add_foreign_key "attachments", "issues"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "issues"
  add_foreign_key "comments", "users"
  add_foreign_key "cycles", "teams"
  add_foreign_key "initiative_projects", "initiatives"
  add_foreign_key "initiative_projects", "projects"
  add_foreign_key "initiatives", "users", column: "owner_id"
  add_foreign_key "issue_activities", "issues"
  add_foreign_key "issue_activities", "users"
  add_foreign_key "issue_labels", "issues"
  add_foreign_key "issue_labels", "labels"
  add_foreign_key "issue_relations", "issues"
  add_foreign_key "issue_relations", "issues", column: "related_issue_id"
  add_foreign_key "issues", "cycles"
  add_foreign_key "issues", "issues", column: "parent_id"
  add_foreign_key "issues", "projects"
  add_foreign_key "issues", "teams"
  add_foreign_key "issues", "users", column: "assignee_id"
  add_foreign_key "issues", "users", column: "creator_id"
  add_foreign_key "issues", "workflow_states"
  add_foreign_key "labels", "labels", column: "parent_id"
  add_foreign_key "labels", "teams"
  add_foreign_key "project_memberships", "projects"
  add_foreign_key "project_memberships", "users"
  add_foreign_key "project_teams", "projects"
  add_foreign_key "project_teams", "teams"
  add_foreign_key "project_updates", "projects"
  add_foreign_key "project_updates", "users"
  add_foreign_key "projects", "users", column: "lead_id"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "workflow_states", "teams"
end
