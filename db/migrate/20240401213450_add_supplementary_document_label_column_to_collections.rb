class AddSupplementaryDocumentLabelColumnToCollections < ActiveRecord::Migration[7.1]
  def change
    add_column :collections, :supplementary_document_label, :string
  end
end
