class RedesignHosts < ActiveRecord::Migration[6.0]
  def up
    drop_table :hosts if table_exists? :hosts
    drop_table :collections_roles if table_exists? :collections_roles
    drop_table :items_roles if table_exists? :items_roles

    create_table :host_groups do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :pattern, null: false
      t.timestamps
    end

    add_index :host_groups, :key, unique: true

    create_table :collections_host_groups do |t|
      t.integer :collection_id
      t.integer :allowed_host_group_id
      t.integer :denied_host_group_id
      t.timestamps
    end

    add_foreign_key :collections_host_groups, :collections,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :collections_host_groups, :host_groups,
                    column: :allowed_host_group_id,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :collections_host_groups, :host_groups,
                    column: :denied_host_group_id,
                    on_update: :cascade, on_delete: :restrict

    create_table :host_groups_items do |t|
      t.integer :item_id
      t.integer :allowed_host_group_id
      t.integer :denied_host_group_id
      t.integer :effective_allowed_host_group_id
      t.integer :effective_denied_host_group_id
      t.timestamps
    end

    add_foreign_key :host_groups_items, :items,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :host_groups_items, :host_groups,
                    column: :allowed_host_group_id,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :host_groups_items, :host_groups,
                    column: :denied_host_group_id,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :host_groups_items, :host_groups,
                    column: :effective_allowed_host_group_id,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :host_groups_items, :host_groups,
                    column: :effective_denied_host_group_id,
                    on_update: :cascade, on_delete: :restrict
  end

  def down
    drop_table :collections_host_groups
    drop_table :host_groups_items
    drop_table :host_groups
  end
end
