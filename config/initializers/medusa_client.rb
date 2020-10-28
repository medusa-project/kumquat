# Configures the medusa-client gem

require 'configuration'

config = ::Configuration.instance

Medusa::Client.configuration = {
    medusa_base_url: config.medusa_url,
    medusa_user:     config.medusa_user,
    medusa_secret:   config.medusa_secret
}
