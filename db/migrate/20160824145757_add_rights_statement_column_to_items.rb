class AddRightsStatementColumnToItems < ActiveRecord::Migration
  def change
    add_column :items, :rights_statement, :text
  end
end
