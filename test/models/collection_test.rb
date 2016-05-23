require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  def setup
    @col = collections(:collection1)
  end

  test 'content_profile should return a ContentProfile' do
    assert @col.content_profile.kind_of?(ContentProfile)
    @col.content_profile_id = 37
    assert_nil @col.content_profile
  end

  test 'content_profile= should set a ContentProfile' do
    @col.content_profile = ContentProfile::MAP_PROFILE
    assert_equal @col.content_profile_id, ContentProfile::MAP_PROFILE.id
  end

  test 'medusa_url should return the correct URL' do
    # without format
    expected = sprintf('%s/uuids/%s',
                       PearTree::Application.peartree_config[:medusa_url].chomp('/'),
                       @col.repository_id)
    assert_equal(expected, @col.medusa_url)

    # with format
    expected = sprintf('%s/uuids/%s.json',
                       PearTree::Application.peartree_config[:medusa_url].chomp('/'),
                       @col.repository_id)
    assert_equal(expected, @col.medusa_url('json'))
  end

end
