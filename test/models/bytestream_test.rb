require 'test_helper'

class BytestreamTest < ActiveSupport::TestCase

  def setup
    @bs = bytestreams(:iptc)
  end

  test 'byte_size should return the correct size' do
    expected = File.size(@bs.absolute_local_pathname)
    assert_equal(expected, @bs.byte_size)
  end

  test 'byte_size should return nil with invalid pathname set' do
    @bs.repository_relative_pathname = '/bogus'
    assert_nil(@bs.byte_size)
  end

  test 'exists? should return true with valid pathname set' do
    assert(@bs.exists?)
  end

  test 'exists? should return false with invalid pathname set' do
    @bs.repository_relative_pathname = '/bogus'
    assert(!@bs.exists?)
  end

  test 'human_readable_type should work properly' do
    assert_equal 'Preservation Master', bytestreams(:item1_one).human_readable_type
    assert_equal 'Access Master', bytestreams(:item1_two).human_readable_type
  end

  test 'metadata should return metadata' do
    assert @bs.metadata.length > 10
  end

end
