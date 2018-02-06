require 'test_helper'

class AwsS3ClientTest < ActiveSupport::TestCase

  setup do
    @instance = AwsS3Client.new
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

end
