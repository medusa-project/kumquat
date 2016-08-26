class RemoveRightsStatementOrgUriColumnFromItems < ActiveRecord::Migration
  def change
    remove_column :items, :rightsstatements_org_uri
  end
end
