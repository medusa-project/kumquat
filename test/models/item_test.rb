require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  def setup
    @item = Item.new
  end

  test 'access_master_bytestream should work properly' do
    assert_nil(@item.access_master_bytestream)
    bs = Bytestream.new(MedusaFileGroup.new)
    bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
    @item.bytestreams << bs
    assert_not_nil(@item.access_master_bytestream)
  end

  test 'preservation_master_bytestream should work properly' do
    assert_nil(@item.preservation_master_bytestream)
    bs = Bytestream.new(MedusaFileGroup.new)
    bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
    @item.bytestreams << bs
    assert_not_nil(@item.preservation_master_bytestream)
  end

  test 'representative_item should work properly' do
    # for a nil representative item, it should return the instance
    assert_same(@item, @item.representative_item)
    # for a nonexistent representative item, it should return the instance
    @item.representative_item_id = 'bogus'
    assert_same(@item, @item.representative_item)
    # for an existent representative item, it should return the representative item
    col = Collection.find_by_repository_id('misc-test')
    assert_equal('hello_world', col.representative_item_id)
  end

end
