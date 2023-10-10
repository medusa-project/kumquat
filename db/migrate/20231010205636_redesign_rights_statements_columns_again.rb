# This migration might not have been run before
class RedesignRightsStatementsColumnsAgain < ActiveRecord::Migration[7.0]
  def change
    if column_exists?(:collections, :rightsstatements_org_uri) &&
      !column_exists?(:collections, :rights_term_uri)
      rename_column :collections, :rightsstatements_org_uri, :rights_term_uri
    end
    if index_exists?(:vocabulary_terms, :uri)
      remove_index :vocabulary_terms, :uri
    end
    execute "UPDATE vocabulary_terms SET uri = NULL WHERE uri = '';"
    unless index_exists?(:vocabulary_terms, :uri)
      add_index :vocabulary_terms, :uri, unique: true
    end
  end
end
