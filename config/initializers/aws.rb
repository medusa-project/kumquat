# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/index.html

require 'configuration'

config = ::Configuration.instance
opts   = { region: config.aws_region }

Aws.config.update(opts)