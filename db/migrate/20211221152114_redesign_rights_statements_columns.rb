class RedesignRightsStatementsColumns < ActiveRecord::Migration[6.1]
  def change
    rename_column :collections, :rightsstatements_org_uri, :rights_term_uri
    remove_index :vocabulary_terms, :uri
    execute "UPDATE vocabulary_terms SET uri = NULL WHERE uri = '';"
    add_index :vocabulary_terms, :uri, unique: true
  end
end
