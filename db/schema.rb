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

ActiveRecord::Schema[8.0].define(version: 2026_01_22_170000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "issue_id", null: false
    t.uuid "user_id", null: false
    t.uuid "parent_id"
    t.text "body", null: false
    t.text "body_html"
    t.datetime "edited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id", "created_at"], name: "index_comments_on_issue_id_and_created_at"
    t.index ["issue_id"], name: "index_comments_on_issue_id"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
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
    t.index ["issue_id", "label_id"], name: "index_issue_labels_on_issue_id_and_label_id", unique: true
    t.index ["issue_id"], name: "index_issue_labels_on_issue_id"
    t.index ["label_id"], name: "index_issue_labels_on_label_id"
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
    t.index ["assignee_id", "status"], name: "index_issues_on_assignee_id_and_status"
    t.index ["assignee_id"], name: "index_issues_on_assignee_id"
    t.index ["created_at"], name: "index_issues_on_created_at"
    t.index ["creator_id"], name: "index_issues_on_creator_id"
    t.index ["due_date"], name: "index_issues_on_due_date"
    t.index ["identifier"], name: "index_issues_on_identifier", unique: true
    t.index ["parent_id"], name: "index_issues_on_parent_id"
    t.index ["priority"], name: "index_issues_on_priority"
    t.index ["project_id", "status"], name: "index_issues_on_project_id_and_status"
    t.index ["project_id"], name: "index_issues_on_project_id"
    t.index ["search_vector"], name: "index_issues_on_search_vector", using: :gin
    t.index ["sort_order"], name: "index_issues_on_sort_order"
    t.index ["status"], name: "index_issues_on_status"
    t.index ["team_id", "number"], name: "index_issues_on_team_id_and_number", unique: true
    t.index ["team_id", "status"], name: "index_issues_on_team_id_and_status"
    t.index ["team_id"], name: "index_issues_on_team_id"
  end

  create_table "labels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id"
    t.string "name", null: false
    t.string "color", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_global_labels_on_name_unique", unique: true, where: "(team_id IS NULL)"
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
    t.index ["lead_id"], name: "index_projects_on_lead_id"
    t.index ["slug"], name: "index_projects_on_slug", unique: true
    t.index ["status"], name: "index_projects_on_status"
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
    t.index ["key"], name: "index_teams_on_key", unique: true
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["magic_link_token"], name: "index_users_on_magic_link_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "issues"
  add_foreign_key "comments", "users"
  add_foreign_key "issue_activities", "issues"
  add_foreign_key "issue_activities", "users"
  add_foreign_key "issue_labels", "issues"
  add_foreign_key "issue_labels", "labels"
  add_foreign_key "issues", "issues", column: "parent_id"
  add_foreign_key "issues", "projects"
  add_foreign_key "issues", "teams"
  add_foreign_key "issues", "users", column: "assignee_id"
  add_foreign_key "issues", "users", column: "creator_id"
  add_foreign_key "labels", "teams"
  add_foreign_key "project_memberships", "projects"
  add_foreign_key "project_memberships", "users"
  add_foreign_key "projects", "users", column: "lead_id"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
end
