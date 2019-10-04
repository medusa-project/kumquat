require 'test_helper'

class CacheItemTest < ActiveSupport::TestCase

  test 'get_or with hit' do
    CacheItem.create!(key: 'key', value: 'cats')
    assert_equal 'cats', CacheItem.get_or('key', 999)
  end

  test 'get_or with miss' do
    result = CacheItem.get_or('bogus', 999) { 'cats' }
    assert_equal 'cats', result
  end

  test 'get_or with expired item' do
    CacheItem.create!(key: 'key', value: 'cats')
    sleep 2
    result = CacheItem.get_or('key', 1) { 'dogs' }
    assert_equal 'dogs', result
  end

end
