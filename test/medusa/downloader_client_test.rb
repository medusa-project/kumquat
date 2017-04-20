require 'test_helper'

class DownloaderClientTest < ActiveSupport::TestCase

  def setup
    @instance = DownloaderClient.new
  end

  # download_url()

  test 'download_url() should raise an error when given an illegal items
  argument' do
    assert_raises ArgumentError do
      @instance.download_url(nil, 'cats')
    end
  end

  test 'download_url() should raise an error when no items are provided' do
    assert_raises ArgumentError do
      @instance.download_url([], 'cats')
    end
  end

  # zip_dirname()

  test 'zip_dirname() should return the correct path for the free-form
  package profile' do
    item = items(:illini_union_dir1_file1)
    binary = item.binaries.select{ |b| b.master_type == Binary::MasterType::ACCESS }.first
    assert_equal '/3707005/access/online/Illini_Union_Photographs/binder_5/banquets',
                 @instance.send(:zip_dirname, binary, PackageProfile::FREE_FORM_PROFILE)
  end

  test 'zip_dirname() should return the correct path for all other package
  profiles' do
    item = items(:illini_union_dir1_file1)
    binary = item.binaries.select{ |b| b.master_type == Binary::MasterType::ACCESS }.first
    assert_equal "/#{item.repository_id}/access/image",
                 @instance.send(:zip_dirname, binary, PackageProfile::COMPOUND_OBJECT_PROFILE)
  end

end
