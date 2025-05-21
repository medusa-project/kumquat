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

ActiveRecord::Schema[7.1].define(version: 2025_05_21_163958) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "agent_relation_types", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "uri", null: false
  end

  create_table "agent_relations", id: :serial, force: :cascade do |t|
    t.integer "agent_id", null: false
    t.integer "related_agent_id", null: false
    t.string "dates"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "agent_relation_type_id", null: false
    t.index ["agent_id", "agent_relation_type_id", "related_agent_id"], name: "by_relationship", unique: true
    t.index ["agent_id"], name: "index_agent_relations_on_agent_id"
    t.index ["related_agent_id"], name: "index_agent_relations_on_related_agent_id"
  end

  create_table "agent_rules", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["abbreviation"], name: "index_agent_rules_on_abbreviation", unique: true
    t.index ["name"], name: "index_agent_rules_on_name", unique: true
  end

  create_table "agent_types", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_agent_types_on_name", unique: true
  end

  create_table "agent_uris", id: :serial, force: :cascade do |t|
    t.string "uri", null: false
    t.integer "agent_id"
    t.boolean "primary", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["agent_id"], name: "index_agent_uris_on_agent_id"
    t.index ["uri"], name: "index_agent_uris_on_uri", unique: true
  end

  create_table "agents", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "begin_date", precision: nil
    t.datetime "end_date", precision: nil
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "agent_rule_id"
    t.integer "agent_type_id"
    t.index ["agent_rule_id"], name: "index_agents_on_agent_rule_id"
    t.index ["agent_type_id"], name: "index_agents_on_agent_type_id"
    t.index ["begin_date"], name: "index_agents_on_begin_date"
    t.index ["end_date"], name: "index_agents_on_end_date"
    t.index ["name"], name: "index_agents_on_name", unique: true
  end

  create_table "binaries", id: :serial, force: :cascade do |t|
    t.integer "master_type"
    t.string "media_type", default: "unknown/unknown"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "item_id"
    t.string "object_key"
    t.string "medusa_uuid"
    t.decimal "byte_size", precision: 15, null: false
    t.integer "width"
    t.integer "height"
    t.integer "media_category"
    t.integer "duration"
    t.boolean "public", default: true, null: false
    t.text "metadata_json"
    t.text "full_text"
    t.text "hocr"
    t.text "tesseract_json"
    t.datetime "ocred_at", precision: nil
    t.index ["item_id"], name: "index_binaries_on_item_id"
    t.index ["master_type"], name: "index_binaries_on_master_type"
    t.index ["media_category"], name: "index_binaries_on_media_category"
    t.index ["media_type"], name: "index_binaries_on_media_type"
    t.index ["object_key"], name: "index_binaries_on_object_key", unique: true
    t.index ["ocred_at"], name: "index_binaries_on_ocred_at"
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
    t.string "representative_medusa_file_id"
    t.string "representative_item_id"
    t.integer "metadata_profile_id"
    t.string "medusa_file_group_uuid"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "medusa_directory_uuid"
    t.integer "package_profile_id"
    t.integer "medusa_repository_id"
    t.text "rights_statement"
    t.string "rights_term_uri"
    t.string "contentdm_alias"
    t.string "physical_collection_url"
    t.boolean "harvestable", default: false, null: false
    t.string "external_id"
    t.integer "descriptive_element_id"
    t.boolean "harvestable_by_idhh", default: false, null: false
    t.boolean "harvestable_by_primo", default: false, null: false
    t.boolean "restricted", default: false, null: false
    t.boolean "publicize_binaries", default: true, null: false
    t.string "representative_image"
    t.string "representation_type", default: "self", null: false
    t.text "access_systems"
    t.text "resource_types"
    t.string "supplementary_document_label"
    t.index ["descriptive_element_id"], name: "index_collections_on_descriptive_element_id"
    t.index ["external_id"], name: "index_collections_on_external_id"
    t.index ["harvestable"], name: "index_collections_on_harvestable"
    t.index ["harvestable_by_idhh"], name: "index_collections_on_harvestable_by_idhh"
    t.index ["harvestable_by_primo"], name: "index_collections_on_harvestable_by_primo"
    t.index ["metadata_profile_id"], name: "index_collections_on_metadata_profile_id"
    t.index ["public_in_medusa"], name: "index_collections_on_public_in_medusa"
    t.index ["published_in_dls"], name: "index_collections_on_published"
    t.index ["repository_id"], name: "index_collections_on_identifier", unique: true
    t.index ["repository_id"], name: "index_collections_on_repository_id", unique: true
    t.index ["representative_item_id"], name: "index_collections_on_representative_item_id"
  end

  create_table "collections_host_groups", force: :cascade do |t|
    t.integer "collection_id"
    t.integer "allowed_host_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allowed_host_group_id"], name: "index_collections_host_groups_on_allowed_host_group_id"
    t.index ["collection_id"], name: "index_collections_host_groups_on_collection_id"
  end

  create_table "downloads", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.integer "task_id"
    t.boolean "expired", default: false
    t.string "ip_address"
    t.string "object_key"
    t.index ["expired"], name: "index_downloads_on_expired"
    t.index ["ip_address"], name: "index_downloads_on_ip_address"
    t.index ["task_id"], name: "index_downloads_on_task_id"
  end

  create_table "elements", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_elements_on_name", unique: true
  end

  create_table "entity_elements", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at", precision: nil
    t.datetime "performed_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at", precision: nil
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "host_groups", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.text "pattern", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_host_groups_on_key", unique: true
  end

  create_table "host_groups_items", force: :cascade do |t|
    t.integer "item_id"
    t.integer "allowed_host_group_id"
    t.integer "effective_allowed_host_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allowed_host_group_id"], name: "index_host_groups_items_on_allowed_host_group_id"
    t.index ["effective_allowed_host_group_id"], name: "index_host_groups_items_on_effective_allowed_host_group_id"
    t.index ["item_id"], name: "index_host_groups_items_on_item_id"
  end

  create_table "item_sets", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "collection_repository_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["collection_repository_id"], name: "index_item_sets_on_collection_repository_id"
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
    t.string "representative_item_id"
    t.string "variant"
    t.integer "page_number"
    t.integer "subpage_number"
    t.datetime "start_date", precision: nil
    t.boolean "published", default: true
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "contentdm_pointer"
    t.string "contentdm_alias"
    t.string "embed_tag"
    t.string "representative_medusa_file_id"
    t.datetime "end_date", precision: nil
    t.datetime "published_at", precision: nil
    t.boolean "expose_full_text_search", default: true, null: false
    t.string "representative_image"
    t.string "representation_type", default: "self", null: false
    t.text "allowed_netids"
    t.boolean "ocred"
    t.index ["collection_repository_id"], name: "index_items_on_collection_identifier"
    t.index ["parent_repository_id"], name: "index_items_on_parent_identifier"
    t.index ["published"], name: "index_items_on_published"
    t.index ["published_at"], name: "index_items_on_published_at"
    t.index ["repository_id"], name: "index_items_on_identifier", unique: true
    t.index ["representative_item_id"], name: "index_items_on_representative_item_identifier"
    t.index ["variant"], name: "index_items_on_variant"
  end

  create_table "metadata_profile_elements", id: :serial, force: :cascade do |t|
    t.integer "metadata_profile_id"
    t.string "name"
    t.string "label"
    t.integer "index"
    t.boolean "searchable", default: true
    t.boolean "facetable", default: true
    t.boolean "visible", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "sortable", default: true
    t.string "dc_map"
    t.string "dcterms_map"
    t.integer "data_type", default: 0, null: false
    t.boolean "indexed", default: true
    t.integer "facet_order", default: 0, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "default_sortable_element_id"
    t.index ["default"], name: "index_metadata_profiles_on_default"
    t.index ["default_sortable_element_id"], name: "index_metadata_profiles_on_default_sortable_element_id"
    t.index ["name"], name: "index_metadata_profiles_on_name"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "tasks", id: :serial, force: :cascade do |t|
    t.string "name"
    t.decimal "status"
    t.string "status_text"
    t.string "job_id"
    t.float "percent_complete", default: 0.0
    t.datetime "stopped_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "indeterminate", default: false
    t.text "detail"
    t.text "backtrace"
    t.datetime "started_at", precision: nil
    t.string "queue"
    t.bigint "user_id"
    t.index ["created_at"], name: "index_tasks_on_created_at"
    t.index ["job_id"], name: "index_tasks_on_job_id", unique: true
    t.index ["queue"], name: "index_tasks_on_queue"
    t.index ["started_at"], name: "index_tasks_on_started_at"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["stopped_at"], name: "index_tasks_on_stopped_at"
    t.index ["updated_at"], name: "index_tasks_on_updated_at"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "username", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "api_key"
    t.boolean "human", default: true, null: false
    t.datetime "last_logged_in_at"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vocabularies", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["key"], name: "index_vocabularies_on_key", unique: true
  end

  create_table "vocabulary_terms", id: :serial, force: :cascade do |t|
    t.string "string"
    t.string "uri"
    t.integer "vocabulary_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["string"], name: "index_vocabulary_terms_on_string"
    t.index ["uri"], name: "index_vocabulary_terms_on_uri", unique: true
    t.index ["vocabulary_id"], name: "index_vocabulary_terms_on_vocabulary_id"
  end

  create_table "watches", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "collection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.index ["user_id", "collection_id"], name: "index_watches_on_user_id_and_collection_id", unique: true
  end

  add_foreign_key "agent_relations", "agent_relation_types", on_update: :cascade, on_delete: :restrict
  add_foreign_key "agent_relations", "agents", column: "related_agent_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "agent_relations", "agents", on_update: :cascade, on_delete: :cascade
  add_foreign_key "agent_uris", "agents", on_update: :cascade, on_delete: :cascade
  add_foreign_key "agents", "agent_rules", on_update: :cascade, on_delete: :restrict
  add_foreign_key "agents", "agent_types", on_update: :cascade, on_delete: :restrict
  add_foreign_key "binaries", "items", on_delete: :cascade
  add_foreign_key "collections", "metadata_profile_elements", column: "descriptive_element_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "collections_host_groups", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "collections_host_groups", "host_groups", column: "allowed_host_group_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "entity_elements", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "entity_elements", "items", on_delete: :cascade
  add_foreign_key "entity_elements", "vocabularies", on_delete: :restrict
  add_foreign_key "host_groups_items", "host_groups", column: "allowed_host_group_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "host_groups_items", "host_groups", column: "effective_allowed_host_group_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "host_groups_items", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "item_sets_items", "item_sets", on_update: :cascade, on_delete: :cascade
  add_foreign_key "item_sets_items", "items", on_update: :cascade, on_delete: :cascade
  add_foreign_key "item_sets_users", "item_sets", on_update: :cascade, on_delete: :cascade
  add_foreign_key "item_sets_users", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements", "metadata_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements_vocabularies", "metadata_profile_elements", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profile_elements_vocabularies", "vocabularies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "metadata_profiles", "metadata_profile_elements", column: "default_sortable_element_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "tasks", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "vocabulary_terms", "vocabularies", on_delete: :cascade
  add_foreign_key "watches", "collections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "watches", "users", on_update: :cascade, on_delete: :cascade
end
