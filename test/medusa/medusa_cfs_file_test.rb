require 'test_helper'

class MedusaCfsFileTest < ActiveSupport::TestCase

  def setup
    @cfs = MedusaCfsFile.new
    @cfs.uuid = 'd25db810-c451-0133-1d17-0050569601ca-3'
  end

  test 'file? should work properly' do
    # directory
    assert !MedusaCfsFile.file?('a5379ae0-5ca8-0132-3334-0050569601ca-b')
    # file
    assert MedusaCfsFile.file?('6e3c33c0-5ce3-0132-3334-0050569601ca-f')
  end

  test 'pathname should return the correct pathname' do
    assert_equal(Configuration.instance.repository_pathname.chomp('/') +
                     '/162/2204/1601831/access/1601831_001.jp2',
                 @cfs.pathname)
  end

  test 'repository_relative_pathname should return the correct repository-relative pathname' do
    assert_equal('/162/2204/1601831/access/1601831_001.jp2',
                 @cfs.repository_relative_pathname)
  end

  test 'url should return the correct url' do
    assert_equal(Configuration.instance.medusa_url.chomp('/') +
                     '/uuids/d25db810-c451-0133-1d17-0050569601ca-3',
                 @cfs.url)
  end

end
