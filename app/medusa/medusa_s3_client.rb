##
# Singleton client for accessing the Medusa repository S3 bucket. The instance
# proxies for an {Aws::S3::Client}.
#
# @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html
#
class MedusaS3Client

  include Singleton

  BUCKET = Configuration.instance.medusa_s3_bucket

  def method_missing(method, *args, &block)
    unless @client
      config = ::Configuration.instance
      opts   = { region: config.aws_region }
      # In development & test, these may be drawn from the configuration.
      # In demo & production, we use IAM instance credentials instead.
      if config.medusa_s3_endpoint
        opts[:force_path_style] = true
        opts[:endpoint]         = config.medusa_s3_endpoint
        opts[:credentials]      = Aws::Credentials.new(config.medusa_s3_access_key_id,
                                                       config.medusa_s3_secret_access_key)
      end
      @client = Aws::S3::Client.new(opts)
    end
    @client.send(method, *args, &block)
  end

end
