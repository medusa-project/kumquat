# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/index.html

require 'configuration'

config = ::Configuration.instance

Aws.config.update(region: config.aws_region)
