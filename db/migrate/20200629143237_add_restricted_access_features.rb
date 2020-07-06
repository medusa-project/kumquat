class AddRestrictedAccessFeatures < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :restricted, :boolean, null: false, default: false
    add_column :items, :allowed_netids, :text
  end
end
