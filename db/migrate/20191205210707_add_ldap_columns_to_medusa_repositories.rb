class AddLdapColumnsToMedusaRepositories < ActiveRecord::Migration[6.0]
  def change
    add_column :medusa_repositories, :ldap_admin_domain, :string
    add_column :medusa_repositories, :ldap_admin_group, :string
  end
end
