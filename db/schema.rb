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

ActiveRecord::Schema.define(version: 2019_10_04_143449) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "agent_relation_types", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uri", null: false
  end

  create_table "agent_relations", id: :serial, force: :cascade do |t|
    t.integer "agent_id", null: false
    t.integer "related_agent_id", null: false
    t.string "dates"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "agent_relation_type_id", null: false
    t.index ["agent_id", "agent_relation_type_id", "related_agent_id"], name: "by_relationship", unique: true
    t.index ["agent_id"], name: "index_agent_relations_on_agent_id"
    t.index ["related_agent_id"], name: "index_agent_relations_on_related_agent_id"
  end

  create_table "agent_rules", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abbreviation"], name: "index_agent_rules_on_abbreviation", unique: true
    t.index ["name"], name: "index_agent_rules_on_name", unique: true
  end

  create_table "agent_types", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_agent_types_on_name", unique: true
  end

  create_table "agent_uris", id: :serial, force: :cascade do |t|
    t.string "uri", null: false
    t.integer "agent_id"
    t.boolean "primary", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uri"], name: "index_agent_uris_on_uri", unique: true
  end

  create_table "agents", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "begin_date"
    t.datetime "end_date"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "agent_rule_id"
    t.integer "agent_type_id"
    t.index ["begin_date"], name: "index_agents_on_begin_date"
    t.index ["end_date"], name: "index_agents_on_end_date"
    t.index ["name"], name: "index_agents_on_name", unique: true
  end

  create_table "binaries", id: :serial, force: :cascade do |t|
    t.integer "master_type"
    t.string "media_type", default: "unknown/unknown"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "item_id"
    t.string "object_key"
    t.string "cfs_file_uuid"
    t.decimal "byte_size", precision: 15, null: false
    t.decimal "width", precision: 6
    t.decimal "height", precision: 6
    t.integer "media_category"
    t.integer "duration"
    t.index ["item_id"], name: "index_binaries_on_item_id"
    t.index ["master_type"], name: "index_binaries_on_master_type"
    t.index ["media_category"], name: "index_binaries_on_media_category"
    t.index ["media_type"], name: "index_binaries_on_media_type"
    t.index ["object_key"], name: "index_binaries_on_object_key", unique: true
  end

  create_table "cache_items", force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_cache_items_on_key", unique: true
  end

  create_table "collection_joins", id: :serial, force: :cascade do |t|
    t.string "parent_repository_id", null: false
    t.string "child_repository_id", null: false
    t.index ["child_repository_id"], name: "index_collection_joins_on_child_identifier"
    t.index ["parent_repository_id"], name: "index_collection_joins_on_parent_identifier"
  end

  create_table "collections", id: :serial, force: :cascade do |t|
    t.string "repository_id", null: false
    t.string "description_html"
    t.string "access_url"
    t.boolean "public_in_medusa"
    t.boolean "published_in_dls", default: false
    t.string "representative_image"
    t.string "representative_item_id"
    t.integer "metadata_profile_id"
    t.string "medusa_file_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "resource_types"
    t.string "medusa_cfs_directory_id"
    t.integer "package_profile_id"
    t.text "access_systems"
    t.integer "medusa_repository_id"
    t.text "rights_statement"
    t.string "rightsstatements_org_uri"
    t.string "contentdm_alias"
    t.string "physical_collection_url"
    t.boolean "harvestable", default: false
    t.string "external_id"
    t.integer "descriptive_element_id"
    t.index ["external_id"], name: "index_collections_on_external_id"
    t.index ["harvestable"], name: "index_collections_on_harvestable"
    t.index ["metadata_profile_id"], name: "index_collections_on_metadata_profile_id"
    t.index ["public_in_medusa"], name: "index_collections_on_public_in_medusa"
    t.index ["published_in_dls"], name: "index_collections_on_published"
    t.index ["repository_id"], name: "index_collections_on_identifier", unique: true
    t.index ["repository_id"], name: "index_collections_on_repository_id", unique: true
    t.index ["representative_item_id"], name: "index_collections_on_representative_item_id"
  end

  create_table "collections_roles", id: :serial, force: :cascade do |t|
    t.integer "collection_id"
    t.integer "allowed_role_id"
    t.integer "denied_role_id"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "downloads", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "task_id"
    t.boolean "expired", default: false
    t.string "ip_address"
    t.index ["expired"], name: "index_downloads_on_expired"
    t.index ["ip_address"], name: "index_downloads_on_ip_address"
  end

  create_table "elements", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_elements_on_name", unique: true
  end

  create_table "entity_elements", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "item_id"
    t.integer "vocabulary_id"
    t.string "uri"
    t.string "type"
    t.integer "collection_id"
    t.index ["collection_id"], name: "index_entity_elements_on_collection_id"
    t.index ["item_id"], name: "index_entity_elements_on_item_id"
    t.index ["name"], name: "index_entity_elements_on_name"
    t.index ["type"], name: "index_entity_elements_on_type"
    t.index ["vocabulary_id"], name: "index_entity_elements_on_vocabulary_id"
  end

  create_table "hosts", id: :serial, force: :cascade do |t|
    t.string "pattern"
    t.integer "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_sets", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "collection_repository_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_sets_items", id: :serial, force: :cascade do |t|
    t.integer "item_set_id"
    t.integer "item_id"
    t.index ["item_set_id", "item_id"], name: "index_item_sets_items_on_item_set_id_and_item_id", unique: true
  end

  create_table "item_sets_users", id: :serial, force: :cascade do |t|
    t.integer "item_set_id"
    t.integer "user_id"
    t.index ["item_set_id", "user_id"], name: "index_item_sets_users_on_item_set_id_and_user_id", unique: true
  end

  create_table "items", id: :serial, force: :cascade do |t|
    t.string "repository_id", null: false
    t.string "collection_repository_id"
    t.string "parent_repository_id"
    t.string "representative_item_repository_id"
    t.string "variant"
    t.integer "page_number"
    t.integer "subpage_number"
    t.datetime "start_date"
    t.boolean "published", default: true
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "contentdm_pointer"
    t.string "contentdm_alias"
    t.string "embed_tag"
    t.integer "representative_binary_id"
    t.datetime "end_date"
    t.index ["collection_repository_id"], name: "index_items_on_collection_identifier"
    t.index ["parent_repository_id"], name: "index_items_on_parent_identifier"
    t.index ["published"], name: "index_items_on_published"
    t.index ["repository_id"], name: "index_items_on_identifier", unique: true
    t.index ["representative_item_repository_id"], name: "index_items_on_representative_item_identifier"
    t.index ["variant"], name: "index_items_on_variant"
  end

  create_table "items_roles", id: :serial, force: :cascade do |t|
    t.integer "item_id"
    t.integer "allowed_role_id"
    t.integer "denied_role_id"
    t.integer "effective_allowed_role_id"
    t.integer "effective_denied_role_id"
  end

  create_table "medusa_cfs_directories", id: :serial, force: :cascade do |t|
    t.string "uuid", null: false
    t.string "parent_uuid"
    t.string "repository_relative_pathname", null: false
    t.integer "medusa_database_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_medusa_cfs_directories_on_uuid"
  end

  create_table "medusa_cfs_files", id: :serial, force: :cascade do |t|
    t.string "uuid", null: false
    t.string "directory_uuid", null: false
    t.string "media_type"
    t.string "repository_relative_pathname", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_medusa_cfs_files_on_uuid"
  end

  create_table "medusa_file_groups", id: :serial, force: :cascade do |t|
    t.string "uuid"
    t.string "cfs_directory_uuid"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_medusa_file_groups_on_uuid"
  end

  create_table "medusa_repositories", id: :serial, force: :cascade do |t|
    t.integer "medusa_database_id"
    t.string "contact_email"
    t.string "email"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medusa_database_id"], name: "index_medusa_repository_names_on_medusa_database_id"
  end

  create_table "metadata_profile_elements", id: :serial, force: :cascade do |t|
    t.integer "metadata_profile_id"
    t.string "name"
    t.string "label"
    t.integer "index"
    t.boolean "searchable", default: true
    t.boolean "facetable", default: true
    t.boolean "visible", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "sortable", default: true
    t.string "dc_map"
    t.string "dcterms_map"
    t.integer "data_type", default: 0, null: false
    t.boolean "indexed", default: true
    t.index ["facetable"], name: "index_metadata_profile_elements_on_facetable"
    t.index ["index"], name: "index_metadata_profile_elements_on_index"
    t.index ["indexed"], name: "index_metadata_profile_elements_on_indexed"
    t.index ["metadata_profile_id"], name: "index_metadata_profile_elements_on_metadata_profile_id"
    t.index ["name"], name: "index_metadata_profile_elements_on_name"
    t.index ["searchable"], name: "index_metadata_profile_elements_on_searchable"
    t.index ["sortable"], name: "index_metadata_profile_elements_on_sortable"
    t.index ["visible"], name: "index_metadata_profile_elements_on_visible"
  end

  create_table "metadata_profile_elements_vocabularies", id: false, force: :cascade do |t|
    t.integer "metadata_profile_element_id", null: false
    t.integer "vocabulary_id", null: false
  end

  create_table "metadata_profiles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "default_sortable_element_id"
    t.index ["default"], name: "index_metadata_profiles_on_default"
    t.index ["default_sortable_element_id"], name: "index_metadata_profiles_on_default_sortable_element_id"
    t.index ["name"], name: "index_metadata_profiles_on_name"
  end

  create_table "options", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_options_on_key", unique: true
  end

  create_table "permissions", id: :serial, force: :cascade do |t|
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions_roles", id: :serial, force: :cascade do |t|
    t.integer "permission_id"
    t.integer "role_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "name"
    t.boolean "required"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "note"
    t.index ["key"], name: "index_roles_on_key"
  end

  create_table "roles_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  create_table "tasks", id: :serial, force: :cascade do |t|
    t.string "name"
    t.decimal "status"
    t.string "status_text"
    t.string "job_id"
    t.float "percent_complete", default: 0.0
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "indeterminate", default: false
    t.text "detail"
    t.text "backtrace"
    t.datetime "started_at"
    t.string "queue"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "username", null: false
    t.boolean "enabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_key"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vocabularies", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_vocabularies_on_key", unique: true
  end

  create_table "vocabulary_terms", id: :serial, force: :cascade do |t|
    t.string "string"
    t.string "uri"
    t.integer "vocabulary_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["string"], name: "index_vocabulary_terms_on_string"
    t.index ["uri"], name: "index_vocabulary_terms_on_uri"
    t.index ["vocabulary_id"], name: "index_vocabulary_terms_on_vocabulary_id"
  end

  add_foreign_key "agent_relations", "agent_relation_types", on_update: :cascade, on_delete: :restrict
  add_foreign_key "agent_relations", "agents", column: "related_agent_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "agent_relations", "agents", on_update: :cascade, on_delete: :cascade
  add_foreign_key "agent_uris", "agents", on_update: :cascade, on_delete: :cascade
  add_foreign_key "agents", "agent_rules", on_update: :cascade, on_delete: :restrict
  add_foreign_key "agents", "agent_types", on_update: :cascade, on_delete: :restrict
  add_foreign_key "binaries", "items", on_delete: :cascade
  add_foreign_key "collections", "metadata_profile_elements", column: "descriptive_element_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "collections_roles", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collections_roles", "roles", column: "allowed_role_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collections_roles", "roles", column: "denied_role_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "entity_elements", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "entity_elements", "items", on_delete: :cascade
  add_foreign_key "entity_elements", "vocabularies", on_delete: :restrict
  add_foreign_key "hosts", "roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "item_sets_items", "item_sets", on_update: :cascade, on_delete: :cascade
  add_foreign_key "item_sets_items", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "item_sets_users", "item_sets", on_update: :cascade, on_delete: :cascade
  add_foreign_key "item_sets_users", "users", on_update: :cascade, on_delete: :cascade
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
