require 'test_helper'

class BytestreamTest < ActiveSupport::TestCase

  def setup
    @bs = Bytestream.new(repository_relative_pathname: '')
  end

  test 'byte_size should return the correct size' do
    @bs.repository_relative_pathname = __FILE__
    expected = File.size(__FILE__)
    assert_equal(expected, @bs.byte_size)
  end

  test 'byte_size should return nil with no pathname set' do
    assert_nil(@bs.byte_size)
  end

  test 'exists? should return false with no pathname set' do
    puts @bs.absolute_local_pathname
    assert(!@bs.exists?)
  end

  test 'exists? should return true with valid pathname set' do
    PearTree::Application.peartree_config[:repository_pathname] = '/'
    @bs.repository_relative_pathname = __FILE__
    assert(@bs.exists?)
  end

  test 'exists? should return false with invalid pathname set' do
    PearTree::Application.peartree_config[:repository_pathname] = '/'
    @bs.repository_relative_pathname = __FILE__ + 'bogus'
    assert(!@bs.exists?)
  end

  test 'human_readable_type should work properly' do
    assert_equal 'Access Master', bytestreams(:one).human_readable_type
    assert_equal 'Preservation Master', bytestreams(:two).human_readable_type
  end

end
