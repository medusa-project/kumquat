# Configures the medusa-client gem

require 'configuration'

config = ::Configuration.instance

Medusa::Client.configuration = {
    medusa_base_url: config.medusa_url,
    medusa_user:     config.medusa_user,
    medusa_secret:   config.medusa_secret
}

# Temporary patch to expose public_description from the Medusa repository JSON.
# Remove this once medusa-client gem is updated to include it natively.
Medusa::Repository.class_eval do
  def description
    load
    @description
  end

  private

  def load
    return if @loading || @loaded
    @loading           = true
    struct             = fetch_body
    @contact_email     = struct['contact_email']
    @description       = struct['public_description']
    @email             = struct['email']
    @home_url          = struct['url']
    @id                = struct['id']
    @ldap_admin_domain = struct['ldap_admin_domain']
    @ldap_admin_group  = struct['ldap_admin_group']
    @title             = struct['title']
    @uuid              = struct['uuid']
    struct['collections'].each do |col_struct|
      @collections << Medusa::Collection.with_id(col_struct['id'])
    end
    @loaded = true
  ensure
    @loading = false
  end
end
