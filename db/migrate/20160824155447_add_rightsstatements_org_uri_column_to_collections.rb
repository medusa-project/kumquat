class AddRightsstatementsOrgUriColumnToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :rightsstatements_org_uri, :string
  end
end
