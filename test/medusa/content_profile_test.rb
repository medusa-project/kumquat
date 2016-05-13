require 'test_helper'

class ContentProfileTest < ActiveSupport::TestCase

  # all

  test 'all() should return the correct profiles' do
    all = ContentProfile.all
    assert_equal 2, all.length

    # free-form profile
    assert_equal 0, all[0].id
    assert_equal 'Free-Form', all[0].name

    # map profile
    assert_equal 1, all[1].id
    assert_equal 'Map', all[1].name
  end

  # find

  test 'find() should return the correct profile' do
    assert_not_nil ContentProfile.find(1)
    assert_nil ContentProfile.find(27)
  end

  # parent_id (free-form profile)

  test 'parent_id with the free-form profile should return nil with top-level items' do
    # https://medusa.library.illinois.edu/cfs_directories/414021.json
    item = 'be8d3500-c451-0133-1d17-0050569601ca-9'
    assert_nil ContentProfile::FREE_FORM_PROFILE.parent_id(item)
  end

  test 'parent_id with the free-form profile should return the parent UUID with pages' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    page = 'd853fad0-c451-0133-1d17-0050569601ca-7'
    # https://medusa.library.illinois.edu/cfs_directories/414759.json
    expected_parent = 'd83e6f60-c451-0133-1d17-0050569601ca-8'
    assert_equal expected_parent, ContentProfile::FREE_FORM_PROFILE.parent_id(page)
  end

  # parent_id (map profile)

  test 'parent_id with the map profile should return nil with top-level items' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    item = 'ae3991e0-c451-0133-1d17-0050569601ca-b'
    assert_nil ContentProfile::MAP_PROFILE.parent_id(item)
  end

  test 'parent_id with the map profile should return the parent UUID with pages' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    page = 'd853fad0-c451-0133-1d17-0050569601ca-7'
    # https://medusa.library.illinois.edu/cfs_directories/413276.json
    expected_parent = 'ae3991e0-c451-0133-1d17-0050569601ca-b'
    assert_equal expected_parent, ContentProfile::MAP_PROFILE.parent_id(page)
  end

  test 'parent_id with the map profile should return nil for non-item content' do
    # https://medusa.library.illinois.edu/cfs_directories/414759.json
    bogus = 'd83e6f60-c451-0133-1d17-0050569601ca-8'
    assert_nil ContentProfile::MAP_PROFILE.parent_id(bogus)
  end

end
