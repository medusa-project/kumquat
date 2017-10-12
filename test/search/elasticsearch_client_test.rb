require 'test_helper'

class ElasticsearchClientTest < ActiveSupport::TestCase

  TEST_INDEX = 'test'

  setup do
    @instance = ElasticsearchClient.instance
  end

  test 'current_index_name() works' do
    assert_equal 'dls_1_items_test',
                 ElasticsearchClient.current_index_name(Item)
  end

  test 'current_index_version() works' do
    assert_equal Option::integer(Option::Keys::CURRENT_INDEX_VERSION),
                 ElasticsearchClient.current_index_version
  end

  test 'next_index_name() works' do
    assert_equal 'dls_2_items_test',
                 ElasticsearchClient.next_index_name(Item)
  end

  test 'next_index_version() works' do
    assert_equal Option::integer(Option::Keys::NEXT_INDEX_VERSION),
                 ElasticsearchClient.next_index_version
  end

  test 'create_index() works' do
    name = 'test'
    begin
      @instance.create_index(name)
      assert @instance.index_exists?(name)

      @instance.delete_index(name)
      assert !@instance.index_exists?(name)
    ensure
      @instance.delete_index(name)
    end
  end

  test 'delete_index() works' do
    name = 'test'
    begin
      @instance.create_index(name)
      assert @instance.index_exists?(name)

      @instance.delete_index(name)
      assert !@instance.index_exists?(name)
    ensure
      @instance.delete_index(name)
    end
  end

  test 'index_exists?() works' do
    name = 'test'
    begin
      @instance.create_index(name)
      assert @instance.index_exists?(name)

      @instance.delete_index(name)
      assert !@instance.index_exists?(name)
    ensure
      @instance.delete_index(name)
    end
  end

end
