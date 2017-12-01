class AddRightsStatementColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :rights_statement, :text
  end
end
