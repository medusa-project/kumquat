class RedesignRightsStatementsColumns < ActiveRecord::Migration[6.1]
  def change
    rename_column :collections, :rightsstatements_org_uri, :rights_term_uri
    remove_index :vocabulary_terms, :uri
    add_index :vocabulary_terms, :uri, unique: true
  end
end
