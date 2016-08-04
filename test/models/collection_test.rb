require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  def setup
    @col = collections(:collection1)
    assert @col.valid?
  end

  test 'items_to_tsv should work' do
    expected = "uuid\tparentId\tpreservationMasterPathname\taccessMasterPathname\tvariant\tpageNumber\tsubpageNumber\tlatitude\tlongitude\ttitle\tdescription\tlcsh:subject\ttgm:subject
6e406030-5ce3-0132-3334-0050569601ca-3\ta53add10-5ca8-0132-3334-0050569601ca-7\t\t\tFile\t\t\t\t\t\t\t\t
d29950d0-c451-0133-1d17-0050569601ca-2\tbe8d3500-c451-0133-1d17-0050569601ca-9\tMyString\tMyString\t\t\t\t\t\t\t\t\t
d29edba0-c451-0133-1d17-0050569601ca-c\tbe8d3500-c451-0133-1d17-0050569601ca-9\t\t\t\t\t\t\t\t\t\t\t
a1234567-5ca8-0132-3334-0050569601ca-8\t\t/Volumes/Data/alexd/Projects/PearTree/test/fixtures/images/jpg-iptc.jpg\tMyString\t\t\t\t39.2524300\t-152.2342300\t\t\tCats\tMore cats
be8d3500-c451-0133-1d17-0050569601ca-9\t\t\t\t\t\t\t\t\t\t\t\t
a53add10-5ca8-0132-3334-0050569601ca-7\t\t\t\tDirectory\t\t\t\t\t\t\t\t
cd2d4601-c451-0133-1d17-0050569601ca-8\t\t\t\t\t\t\t\t\t\t\t\t\n"
    assert_equal expected, @col.items_to_tsv
  end

  test 'medusa_cfs_directory_id must be a UUID' do
    @col.medusa_cfs_directory_id = 123
    assert !@col.valid?

    @col.medusa_cfs_directory_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @col.valid?
  end

  test 'medusa_file_group_id must be a UUID' do
    @col.medusa_file_group_id = 123
    assert !@col.valid?

    @col.medusa_file_group_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @col.valid?
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

  test 'repository_id must be a UUID' do
    @col.repository_id = 123
    assert !@col.valid?

    @col.repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @col.valid?
  end

end
