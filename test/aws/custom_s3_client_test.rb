require 'test_helper'

class CustomS3ClientTest < ActiveSupport::TestCase

  setup do
    @instance = CustomS3Client.new
  end

  # download_object()

  test 'download_object() should download an object' do
    key = binaries(:folksong_obj1_preservation).repository_relative_pathname.
        reverse.chomp('/').reverse
    file = Tempfile.new('test')
    begin
      @instance.download_object(key: key,
                                range: 'bytes=0-9',
                                pathname: file.path)
      assert_equal 10, file.size
    ensure
      file.close
      file.unlink
    end
  end

  test 'download_object() should return nil for a missing object' do
    file = Tempfile.new('test')
    begin
      assert_nil @instance.download_object(key: 'bogus',
                                           pathname: file.path)
    ensure
      file.close
      file.unlink
    end
  end

  # get_object()

  test 'get_object() returns an object' do
    key = binaries(:folksong_obj1_preservation).repository_relative_pathname.
        reverse.chomp('/').reverse
    object = @instance.get_object(key: key)
    assert_equal key, object.key
    assert_equal 63798956, object.content_length
  end

  test 'get_object() returns nil for a missing object' do
    assert_nil @instance.get_object(key: 'bogus')
  end

  test 'get_object() with range' do
    key = binaries(:folksong_obj1_preservation).repository_relative_pathname.
        reverse.chomp('/').reverse
    result = @instance.get_object(key: key, range: 'bytes=0-9')
    assert_equal 10, result.body.length
  end

  # object_exists?()

  test 'object_exists?() returns true for an object that exists' do
    key = binaries(:folksong_obj1_preservation).repository_relative_pathname.
        reverse.chomp('/').reverse
    assert @instance.object_exists?(key: key)
  end

  test 'get_object() returns false for an object that does not exist' do
    assert !@instance.object_exists?(key: 'bogus')
  end

  # object_url()

  test 'object_url() returns the correct URL' do
    @instance.access_key_id = 'AKIAIOSFODNN7EXAMPLE'
    @instance.secret_key = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    @instance.region = 'us-east-1'
    @instance.request_timestamp = Time.new(2013, 5, 24, 0, 0, 0, '+00:00')
    @instance.expires = 86400
    bucket = 'examplebucket'
    key = 'test.txt'

    assert_equal 'https://examplebucket.s3.amazonaws.com/test.txt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404',
                 @instance.object_url(bucket, key)
  end

end
