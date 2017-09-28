require 'test_helper'

class BinaryTest < ActiveSupport::TestCase

  class MediaCategoryTest < ActiveSupport::TestCase

    test 'media_category_for_media_type() should return nil for a nil media type' do
      assert_nil Binary::MediaCategory::media_category_for_media_type(nil)
    end

    test 'media_category_for_media_type() should return nil for an unrecognized
    media type' do
      assert_nil Binary::MediaCategory::media_category_for_media_type('image/bogus')
    end

    test 'media_category_for_media_type() should work' do
      assert_equal Binary::MediaCategory::DOCUMENT,
                   Binary::MediaCategory::media_category_for_media_type('application/pdf')
      assert_equal Binary::MediaCategory::IMAGE,
                   Binary::MediaCategory::media_category_for_media_type('image/jpeg')
      assert_equal Binary::MediaCategory::TEXT,
                   Binary::MediaCategory::media_category_for_media_type('text/plain')
    end

  end

  setup do
    @binary = binaries(:illini_union_dir1_dir1_file1)
  end

  # total_byte_size()

  test 'total_byte_size() returns an accurate figure' do
    assert Binary.total_byte_size > 100000
  end

  # absolute_local_pathname()

  test 'absolute_local_pathname() should return the correct pathname' do
    assert_equal Configuration.instance.repository_pathname +
                     @binary.repository_relative_pathname,
                 @binary.absolute_local_pathname
  end

  test 'absolute_local_pathname() should return nil when
  repository_relative_pathname is nil' do
    @binary.repository_relative_pathname = nil
    assert_nil @binary.absolute_local_pathname
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

  test 'exists?() should return false with nil pathname set' do
    @binary.repository_relative_pathname = nil
    assert(!@binary.exists?)
  end

  # filename()

  test 'filename() should return the filename when repository_relative_pathname
  is set' do
    assert_equal('banquets_002.jpg', @binary.filename)
  end

  test 'filename() should return nil when repository_relative_pathname is nil' do
    @binary.repository_relative_pathname = nil
    assert_nil(@binary.filename)
  end

  # human_readable_media_category()

  test 'human_readable_media_category() should work properly' do
    assert_equal 'Audio',
                 Binary.new(media_category: Binary::MediaCategory::AUDIO).
                     human_readable_media_category
    assert_equal 'Binary',
                 Binary.new(media_category: Binary::MediaCategory::BINARY).
                     human_readable_media_category
    assert_equal 'Image',
                 Binary.new(media_category: Binary::MediaCategory::IMAGE).
                     human_readable_media_category
    assert_equal 'Document',
                 Binary.new(media_category: Binary::MediaCategory::DOCUMENT).
                     human_readable_media_category
    assert_equal 'Text',
                 Binary.new(media_category: Binary::MediaCategory::TEXT).
                     human_readable_media_category
    assert_equal '3D',
                 Binary.new(media_category: Binary::MediaCategory::THREE_D).
                     human_readable_media_category
    assert_equal 'Video',
                 Binary.new(media_category: Binary::MediaCategory::VIDEO).
                     human_readable_media_category
  end

  # human_readable_master_type()

  test 'human_readable_master_type should work properly' do
    assert_equal 'Access Master',
                 Binary.new(master_type: Binary::MasterType::ACCESS).human_readable_master_type
    assert_equal 'Preservation Master',
                 Binary.new(master_type: Binary::MasterType::PRESERVATION).human_readable_master_type
  end

  # human_readable_name()

  test 'human_readable_name() should work properly' do
    assert_equal 'JPEG', @binary.human_readable_name
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
    @binary.media_type = 'image/tiff'
    assert @binary.iiif_safe?
    @binary.byte_size = 30000001
    assert !@binary.iiif_safe?
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

  # read_duration()

  test 'read_duration() should work on audio' do
    @binary = binaries(:folksong_obj1_preservation)
    @binary.duration = nil
    @binary.read_duration
    assert_equal 1993, @binary.duration
  end

  test 'read_duration() should work on video' do
    @binary = binaries(:olin_obj1_preservation)
    @binary.duration = nil
    @binary.read_duration
    assert_equal 1846, @binary.duration
  end

  test 'read_duration() should raise an error with missing files' do
    @binary.repository_relative_pathname = 'bogus'
    assert_raises Errno::ENOENT do
      @binary.read_duration
    end
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
