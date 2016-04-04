require 'test_helper'

class MedusaFileGroupTest < ActiveSupport::TestCase

  def setup
    @fg = MedusaFileGroup.new
    @fg.id = 2204
  end

  test 'cfs_directory should return the correct CFS directory' do
    assert_equal(407393, @fg.cfs_directory.id)
  end

  test 'title should return the correct title' do
    assert_equal('Content', @fg.title)
  end

  test 'url should return the correct url' do
    assert_equal(PearTree::Application.peartree_config[:medusa_url].chomp('/') + '/file_groups/2204',
                 @fg.url)
  end

end
