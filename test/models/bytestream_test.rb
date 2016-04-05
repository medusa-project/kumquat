require 'test_helper'

class BytestreamTest < ActiveSupport::TestCase

  def setup
    @bs = Bytestream.new(MedusaFileGroup.new)
  end

  test 'byte_size should return the correct size' do
    @bs.repository_relative_pathname = __FILE__
    expected = File.size(__FILE__)
    assert_equal(expected, @bs.byte_size)
  end

  test 'byte_size should return nil with URL or no pathname set' do
    assert_nil(@bs.byte_size)
    @bs.url = 'http://example.org/'
    assert_nil(@bs.byte_size)
  end

  test 'exists? should return false with no pathname or URL set' do
    assert(!@bs.exists?)
  end

  test 'exists? should return true with valid pathname set' do
    PearTree::Application.peartree_config[:repository_pathname] = '/'
    @bs.repository_relative_pathname = __FILE__
    puts @bs.pathname
    assert(@bs.exists?)
  end

  test 'exists? should return false with invalid pathname set' do
    PearTree::Application.peartree_config[:repository_pathname] = '/'
    @bs.repository_relative_pathname = __FILE__ + 'bogus'
    assert(!@bs.exists?)
  end

  test 'exists? should return true with URL bytestreams' do
    @bs.url = 'http://example.org/'
    assert(@bs.exists?)
  end

end
