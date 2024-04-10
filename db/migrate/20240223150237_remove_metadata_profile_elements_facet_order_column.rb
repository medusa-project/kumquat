class RemoveMetadataProfileElementsFacetOrderColumn < ActiveRecord::Migration[7.1]
  def change
    remove_column :metadata_profile_elements, :facet_order
  end
end
