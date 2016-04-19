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

ActiveRecord::Schema.define(version: 20160419195154) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bytestreams", force: :cascade do |t|
    t.integer  "bytestream_type"
    t.string   "media_type",                   default: "unknown/unknown"
    t.string   "file_group_relative_pathname"
    t.string   "url"
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.integer  "item_id"
  end

  add_index "bytestreams", ["item_id"], name: "index_bytestreams_on_item_id", using: :btree

  create_table "collections", force: :cascade do |t|
    t.string   "repository_id",          null: false
    t.string   "title"
    t.string   "description"
    t.string   "description_html"
    t.string   "access_url"
    t.boolean  "published"
    t.boolean  "published_in_dls"
    t.string   "representative_image"
    t.string   "representative_item_id"
    t.integer  "theme_id"
    t.integer  "metadata_profile_id"
    t.integer  "medusa_file_group_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.datetime "last_indexed"
    t.text     "resource_types"
  end

  add_index "collections", ["metadata_profile_id"], name: "index_collections_on_metadata_profile_id", using: :btree
  add_index "collections", ["published"], name: "index_collections_on_published", using: :btree
  add_index "collections", ["published_in_dls"], name: "index_collections_on_published_in_dls", using: :btree
  add_index "collections", ["repository_id"], name: "index_collections_on_repository_id", unique: true, using: :btree
  add_index "collections", ["representative_item_id"], name: "index_collections_on_representative_item_id", using: :btree
  add_index "collections", ["theme_id"], name: "index_collections_on_theme_id", using: :btree

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

  add_index "element_defs", ["collection_id"], name: "index_element_defs_on_collection_id", using: :btree
  add_index "element_defs", ["metadata_profile_id"], name: "index_element_defs_on_metadata_profile_id", using: :btree

  create_table "elements", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "item_id"
  end

  add_index "elements", ["item_id"], name: "index_elements_on_item_id", using: :btree

  create_table "items", force: :cascade do |t|
    t.string   "repository_id",                                                             null: false
    t.string   "collection_repository_id"
    t.string   "parent_repository_id"
    t.string   "representative_item_repository_id"
    t.string   "variant"
    t.integer  "page_number"
    t.integer  "subpage_number"
    t.datetime "date"
    t.boolean  "published",                                                  default: true
    t.decimal  "latitude",                          precision: 10, scale: 7
    t.decimal  "longitude",                         precision: 10, scale: 7
    t.text     "full_text"
    t.datetime "last_indexed"
    t.datetime "created_at",                                                                null: false
    t.datetime "updated_at",                                                                null: false
  end

  add_index "items", ["collection_repository_id"], name: "index_items_on_collection_repository_id", using: :btree
  add_index "items", ["parent_repository_id"], name: "index_items_on_parent_repository_id", using: :btree
  add_index "items", ["repository_id"], name: "index_items_on_repository_id", unique: true, using: :btree
  add_index "items", ["representative_item_repository_id"], name: "index_items_on_representative_item_repository_id", using: :btree

  create_table "metadata_profiles", force: :cascade do |t|
    t.string   "name"
    t.boolean  "default"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "default_sortable_element_def_id"
  end

  add_index "metadata_profiles", ["default_sortable_element_def_id"], name: "index_metadata_profiles_on_default_sortable_element_def_id", using: :btree

  create_table "options", force: :cascade do |t|
    t.string   "key"
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "options", ["key"], name: "index_options_on_key", unique: true, using: :btree

  create_table "permissions", force: :cascade do |t|
    t.string   "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions_roles", force: :cascade do |t|
    t.integer "permission_id"
    t.integer "role_id"
  end

  add_index "permissions_roles", ["permission_id"], name: "index_permissions_roles_on_permission_id", using: :btree
  add_index "permissions_roles", ["role_id"], name: "index_permissions_roles_on_role_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "key"
    t.string   "name"
    t.boolean  "required"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "roles", ["key"], name: "index_roles_on_key", using: :btree

  create_table "roles_users", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "roles_users", ["role_id"], name: "index_roles_users_on_role_id", using: :btree
  add_index "roles_users", ["user_id"], name: "index_roles_users_on_user_id", using: :btree

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

  add_foreign_key "bytestreams", "items", on_delete: :cascade
  add_foreign_key "element_defs", "metadata_profiles", on_delete: :cascade
  add_foreign_key "elements", "items", on_delete: :cascade
end
