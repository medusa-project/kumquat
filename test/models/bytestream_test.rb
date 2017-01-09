require 'test_helper'

class BytestreamTest < ActiveSupport::TestCase

  def setup
    @bs = bytestreams(:iptc)
  end

  # byte_size

  test 'byte_size should return the correct size' do
    expected = File.size(@bs.absolute_local_pathname)
    assert_equal(expected, @bs.byte_size)
  end

  # exists?()

  test 'exists? should return true with valid pathname set' do
    assert(@bs.exists?)
  end

  test 'exists? should return false with invalid pathname set' do
    @bs.repository_relative_pathname = '/bogus'
    assert(!@bs.exists?)
  end

  # human_readable_type()

  test 'human_readable_type should work properly' do
    assert_equal 'Preservation Master', bytestreams(:item1_one).human_readable_type
    assert_equal 'Access Master', bytestreams(:item1_two).human_readable_type
  end

  # medusa_url()

  test 'medusa_url should return the Medusa URL' do
    assert_equal 'https://medusa.library.illinois.edu/uuids/7400e0a0-5ce3-0132-3334-0050569601ca-c',
                 @bs.medusa_url
  end

  test 'medusa_url should return nil if the CFS file UUID is not set' do
    @bs.cfs_file_uuid = nil
    assert_nil @bs.medusa_url
  end

  # metadata()

  test 'metadata should return metadata' do
    assert @bs.metadata.length > 10
  end

  # read_dimensions()

  test 'read_dimensions() should work on images' do
    @bs.read_dimensions
    assert_equal 2000, @bs.width
    assert_equal 1434, @bs.height
  end

  test 'read_dimensions() should work on videos' do
    # TODO: write this
  end

end
