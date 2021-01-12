require 'test_helper'

class ImageServerTest < ActiveSupport::TestCase

  setup do
    @instance = ImageServer.instance
  end

  test 'purge_all_images_from_cache() works' do
    # curl -v -X POST -u "admin:secret" -H "Content-Type: application/json" http://localhost:8189/tasks -d "{ \"verb\": \"PurgeCache\" }"
    @instance.purge_all_images_from_cache
  end

  test 'purge_collection_item_images_from_cache() works' do
    collection = collections(:compound_object)
    @instance.purge_collection_item_images_from_cache(collection)
  end

  test 'purge_item_images_from_cache() works' do
    item = items(:compound_object_1002_page1)
    @instance.purge_item_images_from_cache(item)
  end

end
