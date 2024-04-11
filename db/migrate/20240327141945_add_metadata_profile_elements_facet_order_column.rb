class AddMetadataProfileElementsFacetOrderColumn < ActiveRecord::Migration[7.1]
  def change
    add_column :metadata_profile_elements, :facet_order, :integer, default: 0, null: false
  end
end
