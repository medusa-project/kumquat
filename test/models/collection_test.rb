require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  def setup
    @col = Collection.new
    @col.repository_id = '162'
  end

  test 'medusa_url should return the correct URL' do
    # without format
    expected = sprintf('%s/collections/%s',
                       PearTree::Application.peartree_config[:medusa_url].chomp('/'),
                       @col.repository_id)
    assert_equal(expected, @col.medusa_url)

    # with format
    expected = sprintf('%s/collections/%s.json',
                       PearTree::Application.peartree_config[:medusa_url].chomp('/'),
                       @col.repository_id)
    assert_equal(expected, @col.medusa_url('json'))
  end

end
