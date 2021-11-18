class ModifyDefaultRepresentationTypeValues < ActiveRecord::Migration[6.1]
  def change
    execute "UPDATE collections SET representation_type = 'self' WHERE representation_type IS NULL OR representation_type = '';"
    change_column_default :collections, :representation_type, "self"
    change_column_null :collections, :representation_type, false

    execute "UPDATE items SET representation_type = 'self' WHERE representation_type IS NULL OR representation_type = '';"
    change_column_default :items, :representation_type, "self"
    change_column_null :items, :representation_type, false
  end
end
