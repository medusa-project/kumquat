require 'test_helper'

class MedusaCollectionTest < ActiveSupport::TestCase

  def setup
    @col = MedusaCollection.new
    @col.id = 162
  end

  test 'file_groups should return the correct file groups' do
    assert_equal(11, @col.file_groups.length)
  end

end
