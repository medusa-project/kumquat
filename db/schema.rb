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

ActiveRecord::Schema.define(version: 20151112165546) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "collection_defs", force: :cascade do |t|
    t.string   "repository_id"
    t.integer  "theme_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "metadata_profile_id"
  end

  create_table "element_defs", force: :cascade do |t|
    t.integer  "collection_id"
    t.integer  "metadata_profile_id"
    t.string   "name"
    t.string   "label"
    t.integer  "index"
    t.boolean  "searchable"
    t.boolean  "facetable"
    t.boolean  "visible"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "facet_def_id"
    t.string   "facet_def_label"
  end

  create_table "facet_defs", force: :cascade do |t|
    t.integer  "index"
    t.string   "name"
    t.string   "solr_field"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "metadata_profiles", force: :cascade do |t|
    t.string   "name"
    t.integer  "collection_id"
    t.boolean  "default"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "options", force: :cascade do |t|
    t.string   "key"
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string   "email"
    t.string   "password_digest"
    t.boolean  "enabled"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

end
