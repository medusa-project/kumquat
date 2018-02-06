##
# S3 client facade class. Wraps either an AwsS3Client or a CustomS3Client.
#
class S3Client

  @wrapped_client

  def initialize
    @wrapped_client = AwsS3Client.new
  end

  ##
  # Downloads an object to a file.
  #
  # @param options [Hash]
  # @option options [String] :key
  # @option options [String] :pathname Pathname to download to.
  # @option options [String] :bucket Optional.
  # @return [void]
  #
  def download_object(options)
    if @wrapped_client.kind_of?(CustomS3Client)
      @wrapped_client.download_object(options)
    else
      @wrapped_client.get_object(options.merge(response_target: options[:pathname]))
    end
  end

  ##
  # @param options [Hash]
  # @option options [String] :key
  # @option options [String] :bucket Optional.
  # @return [S3Object]
  #
  def get_object(options, &block)
    @wrapped_client.get_object(options, &block)
  end

  ##
  # @param options [Hash]
  # @option options [String] :key
  # @option options [String] :bucket Optional.
  # @return [Boolean]
  #
  def object_exists?(key)
    @wrapped_client.object_exists?(key)
  end

end