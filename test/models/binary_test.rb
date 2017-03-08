require 'test_helper'

class BinaryTest < ActiveSupport::TestCase

  def setup
    @binary = binaries(:iptc)
  end

  # absolute_local_pathname()

  test 'absolute_local_pathname() should return the correct pathname' do
    assert_equal Configuration.instance.repository_pathname +
                     @binary.repository_relative_pathname,
                 @binary.absolute_local_pathname
  end

  # as_json()

  test 'as_json() should return the correct structure' do
    b = binaries(:iptc)
    struct = b.as_json
    assert_equal b.human_readable_type, struct['binary_type']
    assert_equal 'image/jpeg', struct['media_type']
    assert_equal '/136/310/3707005/access/online/Illini_Union_Photographs/binder_5/banquets/banquets_002.jpg',
                 struct['repository_relative_pathname']
    assert_equal '7400e0a0-5ce3-0132-3334-0050569601ca-c', struct['cfs_file_uuid']
    assert_equal 1629599, struct['byte_size']
    assert_nil struct['width']
    assert_nil struct['height']
  end

  # byte_size()

  test 'byte_size() should return the correct size' do
    expected = File.size(@binary.absolute_local_pathname)
    assert_equal(expected, @binary.byte_size)
  end

  # exists?()

  test 'exists?() should return true with valid pathname set' do
    assert(@binary.exists?)
  end

  test 'exists?() should return false with invalid pathname set' do
    @binary.repository_relative_pathname = '/bogus'
    assert(!@binary.exists?)
  end

  # filename()

  test 'filename() should return the filename with pathname set' do
    assert_equal('banquets_002.jpg', @binary.filename)
  end

  test 'filename() should return nil with no with pathname set' do
    @binary.repository_relative_pathname = nil
    assert_nil(@binary.filename)
  end

  # human_readable_name()

  test 'human_readable_name() should work properly' do
    assert_equal 'JPEG', @binary.human_readable_name
  end

  # human_readable_type()

  test 'human_readable_type should work properly' do
    assert_equal 'Access Master',
                 Binary.new(binary_type: Binary::Type::ACCESS_MASTER).human_readable_type
    assert_equal 'Preservation Master',
                 Binary.new(binary_type: Binary::Type::PRESERVATION_MASTER).human_readable_type
  end

  # iiif_image_identifier()

  test 'iiif_image_identifier() should return the correct identifier' do
    assert_equal @binary.cfs_file_uuid, @binary.iiif_image_identifier
  end

  # iiif_image_url()

  test 'iiif_image_url() should return the correct URL' do
    assert_equal Configuration.instance.iiif_url + '/' + @binary.cfs_file_uuid,
                 @binary.iiif_image_url
  end

  # iiif_info_url()

  test 'iiif_info_url() should return the correct URL' do
    assert_equal Configuration.instance.iiif_url + '/' + @binary.cfs_file_uuid + '/info.json',
                 @binary.iiif_info_url
  end

  # iiif_safe?()

  test 'iiif_safe?() should return false if the pathname is empty' do
    @binary.repository_relative_pathname = nil
    assert !@binary.iiif_safe?
  end

  test 'iiif_safe?() should return false if the instance is not IIIF-compatible' do
    @binary.media_type = 'application/octet-stream'
    assert !@binary.iiif_safe?

    @binary.media_type = 'text/plain'
    assert !@binary.iiif_safe?
  end

  test 'iiif_safe?() should return false if a TIFF image is too big' do
    # TODO: write this
  end

  test 'iiif_safe?() should return true in all other cases' do
    assert @binary.iiif_safe?
  end

  # infer_media_type()

  test 'infer_media_type() should work properly' do
    @binary.media_type = nil
    @binary.infer_media_type
    assert_equal 'image/jpeg', @binary.media_type
  end

  # medusa_url()

  test 'medusa_url should return the Medusa URL' do
    assert_equal 'https://medusa.library.illinois.edu/uuids/7400e0a0-5ce3-0132-3334-0050569601ca-c',
                 @binary.medusa_url
  end

  test 'medusa_url should return nil if the CFS file UUID is not set' do
    @binary.cfs_file_uuid = nil
    assert_nil @binary.medusa_url
  end

  # metadata()

  test 'metadata should return metadata' do
    assert @binary.metadata.length > 10
  end

  # read_dimensions()

  test 'read_dimensions() should work on images' do
    @binary.width = nil
    @binary.height = nil
    @binary.read_dimensions
    assert_equal 2000, @binary.width
    assert_equal 1434, @binary.height
  end

  test 'read_dimensions() should work on videos' do
    # TODO: write this
  end

  # read_size()

  test 'read_size() should work properly' do
    @binary.byte_size = nil
    @binary.read_size
    assert_equal File.size(@binary.absolute_local_pathname), @binary.byte_size
  end

  test 'read_size() should raise an error with missing files' do
    @binary.repository_relative_pathname = 'bogus'
    assert_raises Errno::ENOENT do
      @binary.read_size
    end
  end

end
