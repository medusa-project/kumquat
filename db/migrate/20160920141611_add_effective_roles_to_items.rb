class AddEffectiveRolesToItems < ActiveRecord::Migration
  def change
    add_column :items_roles, :effective_allowed_role_id, :integer
    add_column :items_roles, :effective_denied_role_id, :integer

    add_foreign_key :items_roles, :roles, column: :effective_allowed_role_id,
                    on_delete: :cascade, on_update: :cascade
    add_foreign_key :items_roles, :roles, column: :effective_denied_role_id,
                    on_delete: :cascade, on_update: :cascade
  end
end
