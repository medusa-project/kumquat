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
    assert MedusaCfsFile.file?('39582239-4307-1cc6-c9c6-074516fd7635')
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
    assert_equal('repositories/1/collections/1/file_groups/1/root/dir1/image1.jpg', @file.pathname)
  end

  # repository_relative_pathname()

  test 'repository_relative_pathname() should return the correct
  repository-relative pathname' do
    assert_equal('repositories/1/collections/1/file_groups/1/root/dir1/image1.jpg',
                 @file.repository_relative_pathname)
  end

  # to_binary()

  test 'to_binary() should return a correct binary' do
    binary = @file.to_binary(Binary::MasterType::PRESERVATION)
    assert_equal Binary::MasterType::PRESERVATION, binary.master_type
    assert_equal @file.repository_relative_pathname, binary.object_key
    assert_equal 6302, binary.byte_size
    assert_equal 'image/jpeg', binary.media_type
    assert_equal Binary::MediaCategory::IMAGE, binary.media_category
    assert_equal 128, binary.width
    assert_equal 112, binary.height
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
                     '/uuids/39582239-4307-1cc6-c9c6-074516fd7635',
                 @file.url)
  end

end
