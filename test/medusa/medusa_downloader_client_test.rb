require 'test_helper'

class MedusaDownloaderClientTest < ActiveSupport::TestCase

  def setup
    @instance = MedusaDownloaderClient.new
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

  # head()

  test 'head() works' do
    assert_nothing_raised do
      @instance.head
    end
  end

  # zip_dirname()

  test 'zip_dirname() should return the correct path' do
    item = items(:illini_union_dir1_dir1_file1)
    binary = item.binaries.select{ |b| b.master_type == Binary::MasterType::ACCESS }.first
    assert_equal '/136/310/3707005/access/online/Illini_Union_Photographs/binder_5/banquets',
                 @instance.send(:zip_dirname, binary)
  end

end
