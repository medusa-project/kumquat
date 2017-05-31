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

ActiveRecord::Schema.define(version: 20170531144224) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "agent_relation_types", force: :cascade do |t|
    t.string   "name",        null: false
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "uri",         null: false
  end

  create_table "agent_relations", force: :cascade do |t|
    t.integer  "agent_id",               null: false
    t.integer  "related_agent_id",       null: false
    t.string   "dates"
    t.text     "description"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "agent_relation_type_id", null: false
  end

  add_index "agent_relations", ["agent_id", "agent_relation_type_id", "related_agent_id"], name: "by_relationship", unique: true, using: :btree
  add_index "agent_relations", ["agent_id"], name: "index_agent_relations_on_agent_id", using: :btree
  add_index "agent_relations", ["related_agent_id"], name: "index_agent_relations_on_related_agent_id", using: :btree

  create_table "agent_rules", force: :cascade do |t|
    t.string   "name",         null: false
    t.string   "abbreviation"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "agent_rules", ["abbreviation"], name: "index_agent_rules_on_abbreviation", unique: true, using: :btree
  add_index "agent_rules", ["name"], name: "index_agent_rules_on_name", unique: true, using: :btree

  create_table "agent_types", force: :cascade do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "agent_types", ["name"], name: "index_agent_types_on_name", unique: true, using: :btree

  create_table "agent_uris", force: :cascade do |t|
    t.string   "uri",                        null: false
    t.integer  "agent_id"
    t.boolean  "primary",    default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "agent_uris", ["uri"], name: "index_agent_uris_on_uri", unique: true, using: :btree

  create_table "agents", force: :cascade do |t|
    t.string   "name",          null: false
    t.datetime "begin_date"
    t.datetime "end_date"
    t.text     "description"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "agent_rule_id"
    t.integer  "agent_type_id"
  end

  add_index "agents", ["begin_date"], name: "index_agents_on_begin_date", using: :btree
  add_index "agents", ["end_date"], name: "index_agents_on_end_date", using: :btree
  add_index "agents", ["name"], name: "index_agents_on_name", unique: true, using: :btree

  create_table "binaries", force: :cascade do |t|
    t.integer  "master_type"
    t.string   "media_type",                                  default: "unknown/unknown"
    t.datetime "created_at",                                                              null: false
    t.datetime "updated_at",                                                              null: false
    t.integer  "item_id"
    t.string   "repository_relative_pathname"
    t.string   "cfs_file_uuid"
    t.decimal  "byte_size",                    precision: 15
    t.decimal  "width",                        precision: 6
    t.decimal  "height",                       precision: 6
    t.integer  "media_category"
  end

  add_index "binaries", ["item_id"], name: "index_binaries_on_item_id", using: :btree
  add_index "binaries", ["master_type"], name: "index_binaries_on_master_type", using: :btree
  add_index "binaries", ["media_category"], name: "index_binaries_on_media_category", using: :btree
  add_index "binaries", ["media_type"], name: "index_binaries_on_media_type", using: :btree

  create_table "collection_joins", force: :cascade do |t|
    t.string "parent_repository_id", null: false
    t.string "child_repository_id",  null: false
  end

  add_index "collection_joins", ["child_repository_id"], name: "index_collection_joins_on_child_repository_id", using: :btree
  add_index "collection_joins", ["parent_repository_id"], name: "index_collection_joins_on_parent_repository_id", using: :btree

  create_table "collections", force: :cascade do |t|
    t.string   "repository_id",                            null: false
    t.string   "description_html"
    t.string   "access_url"
    t.boolean  "published"
    t.boolean  "published_in_dls"
    t.string   "representative_image"
    t.string   "representative_item_id"
    t.integer  "metadata_profile_id"
    t.string   "medusa_file_group_id"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.text     "resource_types"
    t.string   "medusa_cfs_directory_id"
    t.integer  "package_profile_id"
    t.text     "access_systems"
    t.integer  "medusa_repository_id"
    t.text     "rights_statement"
    t.string   "rightsstatements_org_uri"
    t.string   "contentdm_alias"
    t.string   "physical_collection_url"
    t.boolean  "harvestable",              default: false
  end

  add_index "collections", ["harvestable"], name: "index_collections_on_harvestable", using: :btree
  add_index "collections", ["metadata_profile_id"], name: "index_collections_on_metadata_profile_id", using: :btree
  add_index "collections", ["published"], name: "index_collections_on_published", using: :btree
  add_index "collections", ["published_in_dls"], name: "index_collections_on_published_in_dls", using: :btree
  add_index "collections", ["repository_id"], name: "index_collections_on_repository_id", unique: true, using: :btree
  add_index "collections", ["representative_item_id"], name: "index_collections_on_representative_item_id", using: :btree

  create_table "collections_roles", force: :cascade do |t|
    t.integer "collection_id"
    t.integer "allowed_role_id"
    t.integer "denied_role_id"
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

  create_table "downloads", force: :cascade do |t|
    t.string   "key",                            null: false
    t.integer  "status",           default: 0,   null: false
    t.string   "filename"
    t.float    "percent_complete", default: 0.0
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "elements", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "elements", ["name"], name: "index_elements_on_name", unique: true, using: :btree

  create_table "entity_elements", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "item_id"
    t.integer  "vocabulary_id"
    t.string   "uri"
    t.string   "type"
    t.integer  "collection_id"
  end

  add_index "entity_elements", ["collection_id"], name: "index_entity_elements_on_collection_id", using: :btree
  add_index "entity_elements", ["item_id"], name: "index_entity_elements_on_item_id", using: :btree
  add_index "entity_elements", ["name"], name: "index_entity_elements_on_name", using: :btree
  add_index "entity_elements", ["type"], name: "index_entity_elements_on_type", using: :btree
  add_index "entity_elements", ["vocabulary_id"], name: "index_entity_elements_on_vocabulary_id", using: :btree

  create_table "hosts", force: :cascade do |t|
    t.string   "pattern"
    t.integer  "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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
    t.datetime "created_at",                                                                null: false
    t.datetime "updated_at",                                                                null: false
    t.integer  "contentdm_pointer"
    t.string   "contentdm_alias"
    t.string   "embed_tag"
    t.integer  "representative_binary_id"
  end

  add_index "items", ["collection_repository_id"], name: "index_items_on_collection_repository_id", using: :btree
  add_index "items", ["parent_repository_id"], name: "index_items_on_parent_repository_id", using: :btree
  add_index "items", ["published"], name: "index_items_on_published", using: :btree
  add_index "items", ["repository_id"], name: "index_items_on_repository_id", unique: true, using: :btree
  add_index "items", ["representative_item_repository_id"], name: "index_items_on_representative_item_repository_id", using: :btree
  add_index "items", ["variant"], name: "index_items_on_variant", using: :btree

  create_table "items_roles", force: :cascade do |t|
    t.integer "item_id"
    t.integer "allowed_role_id"
    t.integer "denied_role_id"
    t.integer "effective_allowed_role_id"
    t.integer "effective_denied_role_id"
  end

  create_table "medusa_cfs_directories", force: :cascade do |t|
    t.string   "uuid",                         null: false
    t.string   "parent_uuid"
    t.string   "repository_relative_pathname", null: false
    t.integer  "medusa_database_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "medusa_cfs_directories", ["uuid"], name: "index_medusa_cfs_directories_on_uuid", using: :btree

  create_table "medusa_cfs_files", force: :cascade do |t|
    t.string   "uuid",                         null: false
    t.string   "directory_uuid",               null: false
    t.string   "media_type"
    t.string   "repository_relative_pathname", null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "medusa_cfs_files", ["uuid"], name: "index_medusa_cfs_files_on_uuid", using: :btree

  create_table "medusa_file_groups", force: :cascade do |t|
    t.string   "uuid"
    t.string   "cfs_directory_uuid"
    t.string   "title"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "medusa_file_groups", ["uuid"], name: "index_medusa_file_groups_on_uuid", using: :btree

  create_table "medusa_repositories", force: :cascade do |t|
    t.integer  "medusa_database_id"
    t.string   "contact_email"
    t.string   "email"
    t.string   "title"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "medusa_repositories", ["medusa_database_id"], name: "index_medusa_repositories_on_medusa_database_id", using: :btree

  create_table "metadata_profile_elements", force: :cascade do |t|
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
    t.string   "dc_map"
    t.string   "dcterms_map"
  end

  add_index "metadata_profile_elements", ["facetable"], name: "index_metadata_profile_elements_on_facetable", using: :btree
  add_index "metadata_profile_elements", ["index"], name: "index_metadata_profile_elements_on_index", using: :btree
  add_index "metadata_profile_elements", ["metadata_profile_id"], name: "index_metadata_profile_elements_on_metadata_profile_id", using: :btree
  add_index "metadata_profile_elements", ["name"], name: "index_metadata_profile_elements_on_name", using: :btree
  add_index "metadata_profile_elements", ["searchable"], name: "index_metadata_profile_elements_on_searchable", using: :btree
  add_index "metadata_profile_elements", ["sortable"], name: "index_metadata_profile_elements_on_sortable", using: :btree
  add_index "metadata_profile_elements", ["visible"], name: "index_metadata_profile_elements_on_visible", using: :btree

  create_table "metadata_profile_elements_vocabularies", id: false, force: :cascade do |t|
    t.integer "metadata_profile_element_id", null: false
    t.integer "vocabulary_id",               null: false
  end

  create_table "metadata_profiles", force: :cascade do |t|
    t.string   "name"
    t.boolean  "default",                     default: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "default_sortable_element_id"
  end

  add_index "metadata_profiles", ["default"], name: "index_metadata_profiles_on_default", using: :btree
  add_index "metadata_profiles", ["default_sortable_element_id"], name: "index_metadata_profiles_on_default_sortable_element_id", using: :btree
  add_index "metadata_profiles", ["name"], name: "index_metadata_profiles_on_name", using: :btree

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
    t.text     "detail"
    t.text     "backtrace"
    t.datetime "started_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "username",   null: false
    t.boolean  "enabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "vocabularies", force: :cascade do |t|
    t.string   "key"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "vocabularies", ["key"], name: "index_vocabularies_on_key", unique: true, using: :btree

  create_table "vocabulary_terms", force: :cascade do |t|
    t.string   "string"
    t.string   "uri"
    t.integer  "vocabulary_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "vocabulary_terms", ["string"], name: "index_vocabulary_terms_on_string", using: :btree
  add_index "vocabulary_terms", ["uri"], name: "index_vocabulary_terms_on_uri", using: :btree
  add_index "vocabulary_terms", ["vocabulary_id"], name: "index_vocabulary_terms_on_vocabulary_id", using: :btree

  add_foreign_key "agent_relations", "agent_relation_types", on_update: :cascade, on_delete: :restrict
  add_foreign_key "agent_relations", "agents", column: "related_agent_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "agent_relations", "agents", on_update: :cascade, on_delete: :cascade
  add_foreign_key "agent_uris", "agents", on_update: :cascade, on_delete: :cascade
  add_foreign_key "agents", "agent_rules", on_update: :cascade, on_delete: :restrict
  add_foreign_key "agents", "agent_types", on_update: :cascade, on_delete: :restrict
  add_foreign_key "binaries", "items", on_delete: :cascade
  add_foreign_key "collections_roles", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collections_roles", "roles", column: "allowed_role_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collections_roles", "roles", column: "denied_role_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "entity_elements", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "entity_elements", "items", on_delete: :cascade
  add_foreign_key "entity_elements", "vocabularies", on_delete: :restrict
  add_foreign_key "hosts", "roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "items_roles", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "items_roles", "roles", column: "allowed_role_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "items_roles", "roles", column: "denied_role_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "items_roles", "roles", column: "effective_allowed_role_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "items_roles", "roles", column: "effective_denied_role_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements", "metadata_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements_vocabularies", "metadata_profile_elements", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements_vocabularies", "vocabularies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profiles", "metadata_profile_elements", column: "default_sortable_element_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "permissions_roles", "permissions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "permissions_roles", "roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "roles_users", "roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "roles_users", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "vocabulary_terms", "vocabularies", on_delete: :cascade
end
