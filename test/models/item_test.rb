require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  def setup
    @item = Item.new
  end

  test 'access_master_bytestream should work properly' do
    assert_nil(@item.access_master_bytestream)
    bs = Bytestream.new
    bs.type = Bytestream::Type::ACCESS_MASTER
    @item.bytestreams << bs
    assert_not_nil(@item.access_master_bytestream)
  end

  test 'preservation_master_bytestream should work properly' do
    assert_nil(@item.preservation_master_bytestream)
    bs = Bytestream.new
    bs.type = Bytestream::Type::PRESERVATION_MASTER
    @item.bytestreams << bs
    assert_not_nil(@item.preservation_master_bytestream)
  end

end
