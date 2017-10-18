require 'test_helper'

class ElasticsearchClientTest < ActiveSupport::TestCase

  TEST_INDEX = 'test'

  setup do
    @instance = ElasticsearchClient.instance
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