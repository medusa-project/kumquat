require 'test_helper'

class MedusaCfsDirectoryTest < ActiveSupport::TestCase

  def setup
    @cfs = MedusaCfsDirectory.new
    @cfs.id = 407393
  end

  test 'pathname should return the correct pathname' do
    assert_equal(PearTree::Application.peartree_config[:repository_pathname].chomp('/') + '/162/2204',
                 @cfs.pathname)
  end

  test 'repository_relative_pathname should return the correct repository-relative pathname' do
    assert_equal('/162/2204', @cfs.repository_relative_pathname)
  end

  test 'url should return the correct url' do
    assert_equal(PearTree::Application.peartree_config[:medusa_url].chomp('/') + '/cfs_directories/407393',
                 @cfs.url)
  end

end
