##
# Singleton client for accessing the application S3 bucket. The instance
# proxies for an {Aws::S3::Client}.
#
# @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html
# @see MedusaS3Client
#
class KumquatS3Client

  include Singleton

  BUCKET = Configuration.instance.s3_bucket

  def count_objects(prefix:)
    response = list_objects_v2(bucket: BUCKET, prefix: prefix)
    response.contents.length
  end

  def delete_objects(prefix:)
    response = list_objects_v2(bucket: BUCKET, prefix: prefix)
    response.contents.each do |object|
      delete_object(bucket: BUCKET, key: object.key)
    end
  end

  def method_missing(method, *args, &block)
    unless @client
      config = ::Configuration.instance
      opts   = { region: config.aws_region }
      # In development & test, these may be drawn from the configuration.
      # In demo & production, we use IAM instance credentials instead.
      if config.s3_endpoint
        opts[:force_path_style] = true
        opts[:endpoint]         = config.s3_endpoint
        opts[:credentials]      = Aws::Credentials.new(config.s3_access_key_id,
                                                       config.s3_secret_access_key)
      end
      @client = Aws::S3::Client.new(opts)
    end
    @client.send(method, *args, &block)
  end

  ##
  # @param bucket [String]
  # @param key [String]
  # @return [Boolean]
  #
  def object_exists?(bucket:, key:)
    begin
      head_object(bucket: bucket, key: key)
    rescue Aws::S3::Errors::NotFound
      return false
    else
      return true
    end
  end

  ##
  # @param src_path [String] Local file system path to upload.
  #
  def upload(src_path, key)
    args = {
      body:   src_path,
      bucket: BUCKET,
      key:    key
    }
    put_object(args)
    key
  end

end
