require 'test_helper'

class MedusaCfsDirectoryTest < ActiveSupport::TestCase

  def setup
    @cfs = MedusaCfsDirectory.new
    @cfs.uuid = '7e927880-c12b-0133-1d0f-0050569601ca-4'
  end

  test 'id should return the ID' do
    assert_equal 407393, @cfs.id
  end

  test 'pathname should return the correct pathname' do
    assert_equal(PearTree::Application.peartree_config[:repository_pathname].chomp('/') + '/162/2204',
                 @cfs.pathname)
  end

  test 'repository_relative_pathname should return the correct repository-relative pathname' do
    assert_equal('/162/2204', @cfs.repository_relative_pathname)
  end

  test 'url should return the correct url' do
    assert_equal(PearTree::Application.peartree_config[:medusa_url].chomp('/') +
                     '/uuids/7e927880-c12b-0133-1d0f-0050569601ca-4',
                 @cfs.url)
  end

end
