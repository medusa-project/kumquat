require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  def setup
    @col = Collection.new
    @col.id = 162
  end

  test 'file_groups should return the correct file groups' do
    assert_equal(11, @col.file_groups.length)
  end

end
