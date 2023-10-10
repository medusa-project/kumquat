class RemoveCollectionsRightsstatementsOrgColumn < ActiveRecord::Migration[7.0]
  def change
    if column_exists?(:collections, :rightsstatements_org_uri)
      remove_column :collections, :rightsstatements_org_uri
    end
  end
end
