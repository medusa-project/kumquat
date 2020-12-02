require 'test_helper'

class MedusaDownloaderClientTest < ActiveSupport::TestCase

  def setup
    @instance = MedusaDownloaderClient.new
  end

  # download_url()

  test 'download_url() raises an error when given an illegal items argument' do
    assert_raises ArgumentError do
      @instance.download_url(nil, zip_name: 'cats')
    end
  end

  test 'download_url() raises an error when no items are provided' do
    assert_raises ArgumentError do
      @instance.download_url([], zip_name: 'cats')
    end
  end

  # head()

  test 'head() works' do
    skip if ENV['CI'] == '1' # CI does not have access to the Downloader
    assert_nothing_raised do
      @instance.head
    end
  end

  # zip_dirname()

  test 'zip_dirname() returns the correct path' do
    item   = items(:free_form_dir1_dir1_file1)
    binary = item.binaries.first
    assert_equal '/repositories/1/collections/1/file_groups/1/root/dir1/dir1',
                 @instance.send(:zip_dirname, binary)
  end

end
