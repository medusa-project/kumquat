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
      @client = Aws::S3::Client.new(region: ::Configuration.instance.aws_region)
    end
    @client.send(method, *args, &block)
  end

end
