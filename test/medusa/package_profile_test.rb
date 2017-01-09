require 'test_helper'

class PackageProfileTest < ActiveSupport::TestCase

  # all

  test 'all() should return the correct profiles' do
    all = PackageProfile.all
    assert_equal 3, all.length

    # free-form profile
    assert_equal 0, all[0].id
    assert_equal 'Free-Form', all[0].name

    # map profile
    assert_equal 1, all[1].id
    assert_equal 'Compound Object', all[1].name
  end

  # find

  test 'find() should return the correct profile' do
    assert_not_nil PackageProfile.find(1)
    assert_nil PackageProfile.find(27)
  end

  # ==(obj)

  test '== should work properly' do
    p1 = PackageProfile.new
    p2 = PackageProfile.new
    assert p1 == p2

    p1 = PackageProfile.new
    p1.id = 3
    p2 = PackageProfile.new
    p2.id = 3
    assert p1 == p2

    p1 = PackageProfile.new
    p1.id = 3
    p2 = PackageProfile.new
    p2.id = 4
    assert !(p1 == p2)
  end

  # parent_id_from_medusa

  test 'parent_id_from_medusa should raise an error when no ID is provided' do
    assert_raises ArgumentError do
      PackageProfile::FREE_FORM_PROFILE.parent_id_from_medusa(nil)
    end
  end

  # parent_id_from_medusa (with free-form profile)

  test 'parent_id_from_medusa with the free-form profile should return nil
        with top-level items' do
    # https://medusa.library.illinois.edu/cfs_directories/414021.json
    item = 'be8d3500-c451-0133-1d17-0050569601ca-9'
    assert_nil PackageProfile::FREE_FORM_PROFILE.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa with the free-form profile should return the
        parent UUID with pages' do
    # https://medusa.library.illinois.edu/cfs_directories/111150.json
    page = 'a536b060-5ca8-0132-3334-0050569601ca-8'
    # https://medusa.library.illinois.edu/cfs_directories/111144.json
    expected_parent = 'a53194a0-5ca8-0132-3334-0050569601ca-8'
    assert_equal expected_parent,
                 PackageProfile::FREE_FORM_PROFILE.parent_id_from_medusa(page)
  end

  # parent_id_from_medusa (with map profile)

  test 'parent_id_from_medusa with the map profile should return nil with
        top-level items' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    item = 'ae3991e0-c451-0133-1d17-0050569601ca-b'
    assert_nil PackageProfile::COMPOUND_OBJECT_PROFILE.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa with the map profile should return the parent
        UUID with pages' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    page = 'd853fad0-c451-0133-1d17-0050569601ca-7'
    # https://medusa.library.illinois.edu/cfs_directories/413276.json
    expected_parent = 'ae3991e0-c451-0133-1d17-0050569601ca-b'
    assert_equal expected_parent,
                 PackageProfile::COMPOUND_OBJECT_PROFILE.parent_id_from_medusa(page)
  end

  test 'parent_id_from_medusa with the map profile should return nil for
        non-item content' do
    # https://medusa.library.illinois.edu/cfs_directories/414759.json
    bogus = 'd83e6f60-c451-0133-1d17-0050569601ca-8'
    assert_nil PackageProfile::COMPOUND_OBJECT_PROFILE.parent_id_from_medusa(bogus)
  end

end
