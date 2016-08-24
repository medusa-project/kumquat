class AddRightsStatementColumnToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :rights_statement, :text
  end
end
