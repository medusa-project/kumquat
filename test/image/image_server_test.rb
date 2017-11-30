require 'test_helper'

class ImageServerTest < ActiveSupport::TestCase

  setup do
    @instance = ImageServer.instance
  end

  test 'purge_item_images_from_cache() works' do
    # curl -v -X POST -u "admin:secret" -H "Content-Type: application/json" http://localhost:8189/tasks -d "{ \"verb\": \"PurgeCache\" }"
    item = items(:sanborn_obj1_page1)
    @instance.purge_item_images_from_cache(item)
  end

end
