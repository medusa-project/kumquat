class ChangeSerializationsToJson < ActiveRecord::Migration[7.1]
  def up
    add_column :items, :allowed_netids_json, :text
    result = execute("SELECT id, allowed_netids FROM items WHERE allowed_netids IS NOT NULL;")
    result.each do |row|
      struct = YAML.unsafe_load(row['allowed_netids'])
      json   = JSON.generate(struct)
      execute("UPDATE items SET allowed_netids_json = '#{json}' WHERE id = #{row['id']};")
    end
    rename_column :items, :allowed_netids, :allowed_netids_deleteme
    rename_column :items, :allowed_netids_json, :allowed_netids

    add_column :collections, :access_systems_json, :text
    result = execute("SELECT id, access_systems FROM collections WHERE access_systems IS NOT NULL;")
    result.each do |row|
      struct = YAML.unsafe_load(row['access_systems'])
      json   = JSON.generate(struct)
      execute("UPDATE collections SET access_systems_json = '#{json}' WHERE id = #{row['id']};")
    end
    rename_column :collections, :access_systems, :access_systems_deleteme
    rename_column :collections, :access_systems_json, :access_systems

    add_column :collections, :resource_types_json, :text
    result = execute("SELECT id, resource_types FROM collections WHERE resource_types IS NOT NULL;")
    result.each do |row|
      struct = YAML.unsafe_load(row['resource_types'])
      json   = JSON.generate(struct)
      execute("UPDATE collections SET resource_types_json = '#{json}' WHERE id = #{row['id']};")
    end
    rename_column :collections, :resource_types, :resource_types_deleteme
    rename_column :collections, :resource_types_json, :resource_types
  end

  def down
    remove_column :items, :allowed_netids
    rename_column :items, :allowed_netids_deleteme, :allowed_netids

    remove_column :collections, :access_systems
    rename_column :collections, :access_systems_deleteme, :access_systems

    remove_column :collections, :resource_types
    rename_column :collections, :resource_types_deleteme, :resource_types
  end
end
