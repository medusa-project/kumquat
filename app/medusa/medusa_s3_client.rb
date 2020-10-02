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

  ##
  # Used only in testing. Not for use in production, as the Medusa S3 bucket is
  # read-only.
  #
  # @param src_key [String]
  # @param dest_key [String]
  #
  def move_object(src_key, dest_key)
    copy_object(bucket:      BUCKET,
                copy_source: "/#{BUCKET}/#{src_key}",
                key:         dest_key)
    delete_object(bucket: BUCKET, key: src_key)
  end

  ##
  # Used only in testing. Not for use in production, as the Medusa S3 bucket is
  # read-only.
  #
  # @param src_prefix [String]
  # @param dest_prefix [String]
  #
  def move_objects(src_prefix, dest_prefix)
    response = list_objects_v2(bucket: BUCKET, prefix: src_prefix)
    response.contents.each do |object|
      dest_key = dest_prefix.delete_suffix('/') +
          object.key.delete_prefix(src_prefix)
      move_object(object.key, dest_key)
    end
  end

end
