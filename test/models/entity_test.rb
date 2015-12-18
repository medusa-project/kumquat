require 'test_helper'

class EntityTest < ActiveSupport::TestCase

  def setup
    seed_repository
    @entity = Entity.new
  end

  test 'representative_item should work properly' do
    # for a nil representative item, it should return the instance
    assert_same(@entity, @entity.representative_item)
    # for a nonexistent representative item, it should return the instance
    @entity.representative_item_id = 'bogus'
    assert_same(@entity, @entity.representative_item)
    # for an existent representative item, it should return the representative item
    col = Collection.find('misc-test')
    assert_equal('hello_world', col.representative_item_id)
  end

end
