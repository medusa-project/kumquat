require 'test_helper'

class ContentProfileTest < ActiveSupport::TestCase

  setup do
    tsv = File.read(__dir__ + '/../fixtures/repository/medusa-free-form.tsv')
    @tsv = CSV.parse(tsv, headers: true, col_sep: "\t").map{ |row| row.to_hash }
  end

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

  # bytestreams_from_medusa

  test 'bytestreams_from_medusa should raise an error when no ID is provided' do
    assert_raises ArgumentError do
      ContentProfile::FREE_FORM_PROFILE.bytestreams_from_medusa(nil)
    end
  end

  # bytestreams_from_medusa (with free-form profile)

  test 'bytestreams_from_medusa with the free-form profile should return an empty
        array with top-level items' do
    # https://medusa.library.illinois.edu/cfs_directories/414021.json
    item = 'be8d3500-c451-0133-1d17-0050569601ca-9'
    assert_equal 0, ContentProfile::FREE_FORM_PROFILE.bytestreams_from_medusa(item).length
  end

  test 'bytestreams_from_medusa with the free-form profile should return a
        one-element array with files' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    page = 'd853fad0-c451-0133-1d17-0050569601ca-7'
    bytestreams = ContentProfile::FREE_FORM_PROFILE.bytestreams_from_medusa(page)
    assert_equal 1, bytestreams.length
    assert_equal 1, bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.length
  end

  test 'bytestreams_from_medusa with the free-form profile should return an
        empty array with directories' do
    # https://medusa.library.illinois.edu/cfs_directories/414759.json
    page = 'd83e6f60-c451-0133-1d17-0050569601ca-8'
    bytestreams = ContentProfile::FREE_FORM_PROFILE.bytestreams_from_medusa(page)
    assert_equal 0, bytestreams.length
  end

  # bytestreams_from_medusa (with map profile)

  test 'bytestreams_from_medusa with the map profile should return an empty
        array with top-level items' do
    # https://medusa.library.illinois.edu/cfs_directories/414021.json
    item = 'be8d3500-c451-0133-1d17-0050569601ca-9'
    assert_equal 0, ContentProfile::MAP_PROFILE.bytestreams_from_medusa(item).length
  end

  test 'bytestreams_from_medusa with the map profile should return a
        two-element array with child items' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    page = 'd853fad0-c451-0133-1d17-0050569601ca-7'
    bytestreams = ContentProfile::MAP_PROFILE.bytestreams_from_medusa(page)
    assert_equal 2, bytestreams.length
    assert_equal 1, bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.length
    assert_equal 1, bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.length
  end

  # bytestreams_from_tsv (with free-form profile)

  test 'bytestreams_from_tsv with the free-form profile should return an empty
        array with top-level items' do
    # https://medusa.library.illinois.edu/cfs_directories/414021.json
    item = 'be8d3500-c451-0133-1d17-0050569601ca-9'
    assert_equal 0, ContentProfile::FREE_FORM_PROFILE.bytestreams_from_tsv(item, @tsv).length
  end

  test 'bytestreams_from_tsv with the free-form profile should return a
        one-element array with files' do
    item = '6e406030-5ce3-0132-3334-0050569601ca-3'
    tsv = File.read(__dir__ + '/../fixtures/repository/medusa-free-form.tsv')
    assert_equal 1, ContentProfile::FREE_FORM_PROFILE.bytestreams_from_tsv(item, @tsv).length
  end

  test 'bytestreams_from_tsv with the free-form profile should return an
        empty array with directories' do
    item = 'a5393f70-5ca8-0132-3334-0050569601ca-9'
    assert_equal 0, ContentProfile::FREE_FORM_PROFILE.bytestreams_from_tsv(item, @tsv).length
  end

  # bytestreams_from_tsv (with map profile)

  test 'bytestreams_from_tsv with the map profile should return an empty
        array with top-level items' do
    item = 'ab792720-c451-0133-1d17-0050569601ca-4'
    assert_equal 0, ContentProfile::MAP_PROFILE.bytestreams_from_tsv(item, @tsv).length
  end

  test 'bytestreams_from_tsv with the map profile should return a
        two-element array with child items' do
    item = 'd73e9190-c451-0133-1d17-0050569601ca-2'
    assert_equal 2, ContentProfile::MAP_PROFILE.bytestreams_from_tsv(item, @tsv).length
  end

  # parent_id_from_medusa

  test 'parent_id_from_medusa should raise an error when no ID is provided' do
    assert_raises ArgumentError do
      ContentProfile::FREE_FORM_PROFILE.parent_id_from_medusa(nil)
    end
  end

  # parent_id_from_medusa (with free-form profile)

  test 'parent_id_from_medusa with the free-form profile should return nil
        with top-level items' do
    # https://medusa.library.illinois.edu/cfs_directories/414021.json
    item = 'be8d3500-c451-0133-1d17-0050569601ca-9'
    assert_nil ContentProfile::FREE_FORM_PROFILE.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa with the free-form profile should return the
        parent UUID with pages' do
    # https://medusa.library.illinois.edu/cfs_directories/111150.json
    page = 'a536b060-5ca8-0132-3334-0050569601ca-8'
    # https://medusa.library.illinois.edu/cfs_directories/111144.json
    expected_parent = 'a53194a0-5ca8-0132-3334-0050569601ca-8'
    assert_equal expected_parent,
                 ContentProfile::FREE_FORM_PROFILE.parent_id_from_medusa(page)
  end

  # parent_id_from_medusa (with map profile)

  test 'parent_id_from_medusa with the map profile should return nil with
        top-level items' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    item = 'ae3991e0-c451-0133-1d17-0050569601ca-b'
    assert_nil ContentProfile::MAP_PROFILE.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa with the map profile should return the parent
        UUID with pages' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    page = 'd853fad0-c451-0133-1d17-0050569601ca-7'
    # https://medusa.library.illinois.edu/cfs_directories/413276.json
    expected_parent = 'ae3991e0-c451-0133-1d17-0050569601ca-b'
    assert_equal expected_parent,
                 ContentProfile::MAP_PROFILE.parent_id_from_medusa(page)
  end

  test 'parent_id_from_medusa with the map profile should return nil for
        non-item content' do
    # https://medusa.library.illinois.edu/cfs_directories/414759.json
    bogus = 'd83e6f60-c451-0133-1d17-0050569601ca-8'
    assert_nil ContentProfile::MAP_PROFILE.parent_id_from_medusa(bogus)
  end

end
