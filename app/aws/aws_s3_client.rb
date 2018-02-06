##
# S3 client using the AWS Ruby SDK.
#
class AwsS3Client

  def initialize
    @client = Aws::S3::Client.new
    @bucket = ::Configuration.instance.repository_s3_bucket
  end

  ##
  # @param options [Hash]
  # @option options [String] :key
  # @option options [String] :bucket Optional.
  #
  def get_object(options, &block)
    options[:bucket] = options[:bucket] || @bucket
    begin
      s3object = @client.get_object(options, &block)
      object = S3Object.new
      object.key = options[:key]
      object.body = s3object.body
      object.content_length = s3object.content_length
      return object
    rescue Aws::S3::Errors::NoSuchKey
      return nil
    end
  end

  ##
  # @param options [Hash]
  # @option options [String] :key
  # @option options [String] :bucket Optional.
  #
  def object_exists?(options)
    bucket = Aws::S3::Bucket.new(options[:bucket] || @bucket)
    object = bucket.object(options[:key])
    object.exists?
  end

end