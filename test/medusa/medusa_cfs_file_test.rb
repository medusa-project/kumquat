require 'test_helper'

class MedusaCfsFileTest < ActiveSupport::TestCase

  def setup
    @cfs = MedusaCfsFile.new
    @cfs.id = 9799019
  end

  test 'pathname should return the correct pathname' do
    assert_equal(PearTree::Application.peartree_config[:repository_pathname].chomp('/') +
                     '/162/2204/1601831/access/1601831_001.jp2',
                 @cfs.pathname)
  end

  test 'repository_relative_pathname should return the correct repository-relative pathname' do
    assert_equal('/162/2204/1601831/access/1601831_001.jp2',
                 @cfs.repository_relative_pathname)
  end

  test 'url should return the correct url' do
    assert_equal(PearTree::Application.peartree_config[:medusa_url].chomp('/') + '/cfs_files/9799019',
                 @cfs.url)
  end

end
