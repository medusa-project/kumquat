class AddRightsstatementsOrgUriColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :rightsstatements_org_uri, :string
  end
end
