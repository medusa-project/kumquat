class AddRightsstatementsOrgUriColumns < ActiveRecord::Migration
  def change
    add_column :collections, :rightsstatements_org_uri, :string
    add_column :items, :rightsstatements_org_uri, :string
  end
end
