require 'test_helper'

class MedusaFileGroupTest < ActiveSupport::TestCase

  def setup
    @fg = MedusaFileGroup.new
    @fg.uuid = '7dd36d20-c12b-0133-1d0f-0050569601ca-d'
  end

  test 'cfs_directory should return the correct CFS directory' do
    assert_equal('7e927880-c12b-0133-1d0f-0050569601ca-4', @fg.cfs_directory.uuid)
  end

  test 'title should return the correct title' do
    assert_equal('Content', @fg.title)
  end

  test 'url should return the correct url' do
    assert_equal(PearTree::Application.peartree_config[:medusa_url].chomp('/') +
                     '/uuids/7dd36d20-c12b-0133-1d0f-0050569601ca-d',
                 @fg.url)
  end

end
