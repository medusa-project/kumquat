##
# Singleton client for accessing the Medusa repository S3 bucket. The instance
# proxies for an Aws::S3::Client.
#
# @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html
#
class MedusaS3Client

  include Singleton

  BUCKET = Configuration.instance.medusa_s3_bucket

  CREDENTIALS = Aws::Credentials.new(
      ::Configuration.instance.medusa_s3_bucket_access_key_id,
      ::Configuration.instance.medusa_s3_bucket_secret_key)

  def method_missing(method, *args, &block)
    @client = Aws::S3::Client.new(region: ::Configuration.instance.aws_region,
                                  credentials: CREDENTIALS) unless @client
    @client.send(method, *args, &block)
  end

end
