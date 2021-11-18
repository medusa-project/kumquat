require 'test_helper'

class ImageServerTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @instance = ImageServer.instance
  end

  # binary_image_v2_url()

  test 'binary_image_v2_url() returns a correct URL with minimal arguments' do
    binary = binaries(:compound_object_1002_page2_access)
    url    = ImageServer.binary_image_v2_url(binary: binary)
    config = ::Configuration.instance
    assert_equal config.iiif_image_v2_url + '/' + binary.iiif_image_identifier +
                   "/full/max/0/default.jpg",
                 url
  end

  test 'binary_image_v2_url() returns a correct URL with all arguments' do
    binary = binaries(:compound_object_1002_page2_access)
    url = ImageServer.binary_image_v2_url(binary: binary,
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

  # file_image_v2_url()

  test 'file_image_v2_url() returns a correct URL with minimal arguments' do
    file   = binaries(:compound_object_1002_page2_access).medusa_file
    url    = ImageServer.file_image_v2_url(file: file)
    config = ::Configuration.instance
    assert_equal config.iiif_image_v2_url + '/' + file.uuid +
                   "/full/max/0/default.jpg",
                 url
  end

  test 'file_image_v2_url() returns a correct URL with all arguments' do
    file = binaries(:compound_object_1002_page2_access).medusa_file
    url  = ImageServer.file_image_v2_url(file: file,
                                         region: '0,0,500,500',
                                         size: '300,',
                                         rotation: 15,
                                         color: 'color',
                                         format: 'png',
                                         content_disposition: 'attachment',
                                         filename: 'image.png',
                                         cache: false)
    config = ::Configuration.instance
    assert_equal config.iiif_image_v2_url + '/' + file.uuid +
                   "/0,0,500,500/300,/15/color.png?cache=false&response-content-disposition=attachment%3B+filename%3D%22image.png%22",
                 url
  end

  # s3_image_v2_url()

  test 's3_image_v2_url() returns a correct URL with minimal arguments' do
    url    = ImageServer.s3_image_v2_url(bucket: 'bucket', key: 'key')
    config = ::Configuration.instance
    assert_equal config.iiif_image_v2_url + '/' +
                   CGI.escape("s3://bucket/key") + "/full/max/0/default.jpg",
                 url
  end

  test 's3_image_v2_url() returns a correct URL with all arguments' do
    s3_url = "s3://bucket/key"
    url    = ImageServer.s3_image_v2_url(bucket:              'bucket',
                                         key:                 'key',
                                         region:              '0,0,500,500',
                                         size:                '300,',
                                         rotation:            15,
                                         color:               'color',
                                         format:              'png',
                                         content_disposition: 'attachment',
                                         filename:            'image.png',
                                         cache:               false)
    config = ::Configuration.instance
    assert_equal config.iiif_image_v2_url + '/' + CGI.escape(s3_url) +
                   "/0,0,500,500/300,/15/color.png?cache=false&response-content-disposition=attachment%3B+filename%3D%22image.png%22",
                 url
  end

  # purge_all_images_from_cache()

  test 'purge_all_images_from_cache() works' do
    # curl -v -X POST -u "admin:secret" -H "Content-Type: application/json" http://localhost:8189/tasks -d "{ \"verb\": \"PurgeCache\" }"
    @instance.purge_all_images_from_cache
  end

  # purge_collection_item_images_from_cache()

  test 'purge_collection_item_images_from_cache() works' do
    collection = collections(:compound_object)
    @instance.purge_collection_item_images_from_cache(collection)
  end

  # purge_item_images_from_cache()

  test 'purge_item_images_from_cache() works' do
    item = items(:compound_object_1002_page1)
    @instance.purge_item_images_from_cache(item)
  end

end
