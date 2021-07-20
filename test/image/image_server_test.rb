require 'test_helper'

class ImageServerTest < ActiveSupport::TestCase

  setup do
    @instance = ImageServer.instance
  end

  test 'image_v2_url() returns a correct URL with minimal arguments' do
    binary = binaries(:compound_object_1002_page2_access)
    url    = ImageServer.image_v2_url(binary)
    config = ::Configuration.instance
    assert_equal config.iiif_image_v2_url + '/' + binary.iiif_image_identifier +
                   "/full/max/0/default.jpg",
                 url
  end

  test 'image_v2_url() returns a correct URL with all arguments' do
    binary = binaries(:compound_object_1002_page2_access)
    url = ImageServer.image_v2_url(binary,
                                   region: '0,0,500,500',
                                   size: '300,',
                                   rotation: 15,
                                   color: 'color',
                                   format: 'png',
                                   content_disposition: 'attachment',
                                   filename: 'image.png',
                                   cache: false)
    config = ::Configuration.instance
    assert_equal config.iiif_image_v2_url + '/' + binary.iiif_image_identifier +
                   "/0,0,500,500/300,/15/color.png?cache=false&response-content-disposition=attachment%3B+filename%3D%22image.png%22",
                 url
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
