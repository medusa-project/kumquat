class S3Client

  @wrapped_client

  def initialize
    @wrapped_client = Aws::S3::Client.new
    @bucket = ::Configuration.instance.repository_s3_bucket
  end

  def get_object(options, &block)
    options[:bucket] = options[:bucket] || @bucket
    @wrapped_client.get_object(options, &block)
  end

  def object_exists?(key)
    bucket = Aws::S3::Bucket.new(@bucket)
    object = bucket.object(key)
    object.exists?
  end

end