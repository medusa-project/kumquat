require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  def setup
    @col = collections(:collection1)
  end

  test 'package_profile should return a PackageProfile' do
    assert @col.package_profile.kind_of?(PackageProfile)
    @col.package_profile_id = 37
    assert_nil @col.package_profile
  end

  test 'package_profile= should set a PackageProfile' do
    @col.package_profile = PackageProfile::MAP_PROFILE
    assert_equal @col.package_profile_id, PackageProfile::MAP_PROFILE.id
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
