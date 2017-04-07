require 'test_helper'

class MedusaCfsDirectoryTest < ActiveSupport::TestCase

  def setup
    @dir = MedusaCfsDirectory.new
    @dir.uuid = '7e927880-c12b-0133-1d0f-0050569601ca-4'
  end

  # directories()

  test 'directories should return the directories' do
    @dir = MedusaCfsDirectory.new
    @dir.uuid = '2066c390-e946-0133-1d3d-0050569601ca-d'
    assert_equal 3, @dir.directories.length
  end

  # files()

  test 'files should return the files' do
    @dir = MedusaCfsDirectory.new
    @dir.uuid = '231fa570-e949-0133-1d3d-0050569601ca-2'
    assert_equal 1, @dir.files.length
  end

  # id()

  test 'id should return the ID' do
    assert_equal 407393, @dir.id
  end

  # pathname()

  test 'pathname should return the correct pathname' do
    assert_equal(Configuration.instance.repository_pathname.chomp('/') + '/162/2204',
                 @dir.pathname)
  end

  # repository_relative_pathname()

  test 'repository_relative_pathname should return the correct repository-relative pathname' do
    @dir = MedusaCfsDirectory.new
    @dir.uuid = 'd20a6200-c451-0133-1d17-0050569601ca-1'
    assert_equal('/162/2204/1601831/access', @dir.repository_relative_pathname)
  end

  # url()

  test 'url should return the correct url' do
    assert_equal(Configuration.instance.medusa_url.chomp('/') +
                     '/uuids/7e927880-c12b-0133-1d0f-0050569601ca-4',
                 @dir.url)
  end

end
