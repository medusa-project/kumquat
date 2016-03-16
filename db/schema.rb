# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160316141953) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "collection_defs", force: :cascade do |t|
    t.string   "repository_id"
    t.integer  "theme_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "metadata_profile_id"
    t.string   "medusa_uuid"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "element_defs", force: :cascade do |t|
    t.integer  "collection_id"
    t.integer  "metadata_profile_id"
    t.string   "name"
    t.string   "label"
    t.integer  "index"
    t.boolean  "searchable"
    t.boolean  "facetable"
    t.boolean  "visible"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "sortable",            default: false
  end

  create_table "metadata_profiles", force: :cascade do |t|
    t.string   "name"
    t.integer  "collection_id"
    t.boolean  "default"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "default_sortable_element_def_id"
  end

  create_table "options", force: :cascade do |t|
    t.string   "key"
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.string   "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions_roles", force: :cascade do |t|
    t.integer "permission_id"
    t.integer "role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string   "key"
    t.string   "name"
    t.boolean  "required"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles_users", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string   "name"
    t.decimal  "status"
    t.string   "status_text"
    t.string   "job_id"
    t.float    "percent_complete", default: 0.0
    t.datetime "completed_at"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.boolean  "indeterminate",    default: false
  end

  create_table "themes", force: :cascade do |t|
    t.string   "name"
    t.boolean  "required",   default: false
    t.boolean  "default",    default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "username"
    t.boolean  "enabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
