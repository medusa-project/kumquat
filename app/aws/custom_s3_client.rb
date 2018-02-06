##
# Custom S3 client using a generic HTTP client. Interacts with the S3 v4 API.
#
# @see https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html
#
class CustomS3Client

  SHA256_DIGEST = OpenSSL::Digest.new('sha256')

  attr_accessor :access_key_id, :default_bucket, :expires, :region,
                :request_timestamp, :secret_key

  def initialize
    config = ::Configuration::instance
    self.access_key_id = config.aws_access_key_id
    self.secret_key = config.aws_secret_key
    self.region = config.aws_region
    self.default_bucket = config.repository_s3_bucket
    self.request_timestamp = Time.now.utc
    self.expires = 300

    @client = HTTPClient.new
  end

  ##
  # @param options [Hash]
  # @option options [String] :key      Required.
  # @option options [String] :bucket   Optional.
  # @option options [String] :pathname Pathname to download to.
  # @option options [String] :range    Like `bytes=start-end`
  # @return [nil]
  # @raises [IOError]                  If an unexpected response was received.
  #
  def download_object(options)
    response = request(options)

    case response.status
      when 200, 206 # OK, Partial Content
        file = File.new(options[:pathname], 'wb')
        file.write(response.body)
        file.close
      when 404, 410 # Not Found, Gone
        return nil
      else
        raise IOError, "#{response.status} #{response.reason}"
    end
  end

  ##
  # @param options [Hash]
  # @option options [String] :key    Required.
  # @option options [String] :bucket Optional.
  # @option options [String] :range  Like `bytes=start-end`
  # @return [S3Object]
  # @raises [IOError]                If an unexpected response was received.
  #
  def get_object(options, &block)
    response = request(options)

    case response.status
      when 200, 206 # OK, Partial Content
        object = S3Object.new
        object.key = options[:key]
        object.body = response.body
        object.content_length = response.headers['Content-Length'].to_i
        return object
      when 404, 410 # Not Found, Gone
        return nil
      else
        raise IOError, "#{response.status} #{response.reason}"
    end
  end

  ##
  # @param options [Hash]
  # @option options [String] :key
  # @option options [String] :bucket Optional.
  # @return [Boolean]
  # @raises [IOError] If an unexpected response was received.
  #
  def object_exists?(options)
    bucket = options[:bucket] || self.default_bucket
    key = options[:key]
    url = object_url(bucket, key)

    response = @client.get(url)
    case response.status
      when 200
        return true
      when 404, 410
        return false
      else
        raise IOError, "#{response.status} #{response.reason}"
    end
  end

  def object_url(bucket, key)
    sprintf('%s?%s&X-Amz-Signature=%s',
            canonical_uri(bucket, key),
            canonical_query_string,
            signature(bucket, key))
  end

  private

  def request(options)
    bucket = options[:bucket] || self.default_bucket
    key = options[:key]
    url = object_url(bucket, key)

    headers = {}
    if options[:range]
      headers['Range'] = options[:range]
    end

    @client.get(url, nil, headers)
  end

  def endpoint(bucket)
    sprintf('https://%s.s3.amazonaws.com/', bucket)
  end

  def credential
    sprintf('%s/%s/%s/s3/aws4_request',
            self.access_key_id,
            self.request_timestamp.strftime('%Y%m%d'),
            self.region)
  end

  def canonical_uri(bucket, key)
    sprintf('%s/%s', endpoint(bucket).chomp('/'), CGI.escape(key))
  end

  def canonical_query_string # ordered by query parameter
    sprintf('X-Amz-Algorithm=AWS4-HMAC-SHA256'\
      '&X-Amz-Credential=%s'\
      '&X-Amz-Date=%s'\
      '&X-Amz-Expires=%d'\
      '&X-Amz-SignedHeaders=%s',
            CGI.escape(credential),
            self.request_timestamp.strftime('%Y%m%dT%H%M%SZ'),
            self.expires,
            signed_headers)
  end

  def canonical_headers(bucket) # ordered by header name
    sprintf("host:%s\n", URI.parse(endpoint(bucket)).host)
  end

  def signed_headers # ordered by header name
    'host'
  end

  def canonical_request(bucket, key)
    sprintf("GET\n/%s\n%s\n%s\n%s\nUNSIGNED-PAYLOAD",
            key,
            canonical_query_string,
            canonical_headers(bucket),
            signed_headers)
  end

  def signing_key
    date_key = OpenSSL::HMAC.digest(SHA256_DIGEST,
                                    sprintf('AWS4%s', self.secret_key),
                                    self.request_timestamp.strftime('%Y%m%d'))
    date_region_key = OpenSSL::HMAC.digest(SHA256_DIGEST,
                                           date_key,
                                           self.region)
    date_region_service_key = OpenSSL::HMAC.digest(SHA256_DIGEST,
                                                   date_region_key,
                                                   's3')
    OpenSSL::HMAC.digest(SHA256_DIGEST,
                         date_region_service_key,
                         'aws4_request')
  end

  def string_to_sign(bucket, key)
    sprintf("AWS4-HMAC-SHA256\n%s\n%s/%s/s3/aws4_request\n%s",
            self.request_timestamp.strftime('%Y%m%dT%H%M%SZ'),
            self.request_timestamp.strftime('%Y%m%d'),
            self.region,
            StringUtils.base16(Digest::SHA256.digest(canonical_request(bucket, key))))
  end

  def signature(bucket, key)
    OpenSSL::HMAC.hexdigest(
        SHA256_DIGEST, signing_key, string_to_sign(bucket, key))
  end

end