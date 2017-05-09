require 'test_helper'

class MedusaCfsDirectoryTest < ActiveSupport::TestCase

  def setup
    @dir = medusa_cfs_directories(:one)
  end

  # directories()

  test 'directories should return the directories' do
    assert_equal 3, @dir.directories.length
  end

  # files()

  test 'files should return the files' do
    assert_equal 0, @dir.files.length
  end

  # medusa_database_id()

  test 'medusa_database_id should return the ID' do
    assert_equal 414021, @dir.medusa_database_id
  end

  # pathname()

  test 'pathname should return the correct pathname' do
    assert_equal(Configuration.instance.repository_pathname.chomp('/') + '/162/2204/1601831',
                 @dir.pathname)
  end

  # repository_relative_pathname()

  test 'repository_relative_pathname should return the correct repository-relative pathname' do
    assert_equal('/162/2204/1601831', @dir.repository_relative_pathname)
  end

  # url()

  test 'url should return the correct url' do
    assert_equal(Configuration.instance.medusa_url.chomp('/') +'/uuids/' + @dir.uuid,
                 @dir.url)
  end

end
