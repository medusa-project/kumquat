class RemoveRightsStatementColumnFromItems < ActiveRecord::Migration
  def change
    remove_column :items, :rights_statement
  end
end
