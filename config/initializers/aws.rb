# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/index.html

require 'configuration'

config = ::Configuration.instance
opts   = { region: config.aws_region }

if Rails.env.development? || Rails.env.test?
  # In these environments, credentials are drawn from the application
  # configuration.
  opts[:credentials] = Aws::Credentials.new(config.aws_access_key_id,
                                            config.aws_secret_access_key)
end

Aws.config.update(opts)