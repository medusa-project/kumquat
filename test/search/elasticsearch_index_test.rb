require 'test_helper'

class ElasticsearchIndexTest < ActiveSupport::TestCase

  test 'current_index() returns a correct index' do
    Option.set(Option::Keys::CURRENT_INDEX_VERSION, 0)

    index = ElasticsearchIndex.current_index(Item)
    assert_equal 'dls_0_items_test', index.name
    assert_equal 0, index.version
    assert_not_empty index.schema
  end

  test 'latest_index() returns a correct index' do
    latest_version = ElasticsearchIndex::SCHEMAS.length - 1
    index = ElasticsearchIndex.latest_index(Item)
    assert_equal "dls_#{latest_version}_items_test", index.name
    assert_equal latest_version, index.version
    assert_not_empty index.schema
  end

  test 'exists?() works' do
    # TODO: write this
  end

end
