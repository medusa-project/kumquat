require 'test_helper'

class MedusaCfsFileTest < ActiveSupport::TestCase

  def setup
    @file = medusa_cfs_files(:one)
  end

  # file?()

  test 'file?() should work properly with directories' do
    assert !MedusaCfsFile.file?('a5379ae0-5ca8-0132-3334-0050569601ca-b')
  end

  test 'file?() should work properly with files' do
    assert MedusaCfsFile.file?('6e3c33c0-5ce3-0132-3334-0050569601ca-f')
  end

  # with_uuid()

  test 'with_uuid() should return an instance when given a UUID' do
    file = MedusaCfsFile.with_uuid(@file.uuid)
    assert_equal @file.repository_relative_pathname,
                 file.repository_relative_pathname
    assert_equal @file.media_type, file.media_type
  end

  test 'with_uuid() should cache returned instances' do
    MedusaCfsFile.destroy_all

    assert_nil MedusaCfsFile.find_by_uuid(@file.uuid)
    MedusaCfsFile.with_uuid(@file.uuid)
    assert_not_nil MedusaCfsFile.find_by_uuid(@file.uuid)
  end

  # pathname()

  test 'pathname() should return the correct pathname' do
    assert_equal('/162/2204/1601831/access/1601831_001.jp2', @file.pathname)
  end

  # repository_relative_pathname()

  test 'repository_relative_pathname() should return the correct
  repository-relative pathname' do
    assert_equal('/162/2204/1601831/access/1601831_001.jp2',
                 @file.repository_relative_pathname)
  end

  # to_binary()

  test 'to_binary() should return a correct binary' do
    binary = @file.to_binary(Binary::MasterType::PRESERVATION)
    assert_equal Binary::MasterType::PRESERVATION, binary.master_type
    assert_equal @file.repository_relative_pathname, '/' + binary.object_key
    assert_equal 13173904, binary.byte_size
    assert_equal 'image/jp2', binary.media_type
    assert_equal Binary::MediaCategory::IMAGE, binary.media_category
    assert_equal 3372, binary.width
    assert_equal 4000, binary.height
  end

  test 'to_binary() should override the media category when supplied' do
    binary = @file.to_binary(Binary::MasterType::PRESERVATION,
                             Binary::MediaCategory::VIDEO)
    assert_equal Binary::MasterType::PRESERVATION, binary.master_type
    assert_equal Binary::MediaCategory::VIDEO, binary.media_category
  end

  # url()

  test 'url() should return the correct url' do
    assert_equal(Configuration.instance.medusa_url.chomp('/') +
                     '/uuids/d25db810-c451-0133-1d17-0050569601ca-3',
                 @file.url)
  end

end
