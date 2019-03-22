# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/index.html

config = ::Configuration.instance

Aws.config.update(
    credentials: Aws::Credentials.new(config.dls_aws_access_key_id,
                                      config.dls_aws_secret_key),
    region: config.aws_region)
