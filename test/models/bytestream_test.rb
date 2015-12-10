require 'test_helper'

class BytestreamTest < ActiveSupport::TestCase

  def setup
    @bs = Bytestream.new
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
