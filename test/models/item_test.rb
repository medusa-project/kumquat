require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  def setup
    @item = Item.new
  end

  test 'access_master_bytestream should work properly' do
    assert_nil(@item.access_master_bytestream)
    bs = @item.bytestreams.build
    bs.file_group_relative_pathname = ''
    bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
    bs.save!
    assert_not_nil(@item.access_master_bytestream)
  end

  test 'preservation_master_bytestream should work properly' do
    assert_nil(@item.preservation_master_bytestream)
    bs = @item.bytestreams.build
    bs.file_group_relative_pathname = ''
    bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
    bs.save!
    assert_not_nil(@item.preservation_master_bytestream)
  end

  test 'representative_item should work properly' do
    # nil representative item
    assert_nil(@item.representative_item)
    # nonexistent representative item
    @item.representative_item_repository_id = 'bogus'
    assert_nil(@item.representative_item)
    # for an existent representative item, it should return the representative item
    col = Collection.find_by_repository_id('collection1')
    assert_equal('MyString', col.representative_item_id)
  end

end
