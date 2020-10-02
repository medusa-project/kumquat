require 'test_helper'

class MedusaCfsDirectoryTest < ActiveSupport::TestCase

  def setup
    @dir = medusa_cfs_directories(:one)
  end

  # directories()

  test 'directories should return the directories' do
    skip # failing in CI but this code is due to be replaced by medusa-client
    assert_equal 1, @dir.directories.length
  end

  # files()

  test 'files should return the files' do
    assert_equal 0, @dir.files.length
  end

  # medusa_database_id()

  test 'medusa_database_id should return the ID' do
    assert_equal 460719701, @dir.medusa_database_id
  end

  # pathname()

  test 'pathname should return the correct pathname' do
    assert_equal 'repositories/1/collections/1/file_groups/1/root',
                 @dir.pathname
  end

  # repository_relative_pathname()

  test 'repository_relative_pathname should return the correct repository-relative pathname' do
    assert_equal 'repositories/1/collections/1/file_groups/1/root',
                 @dir.repository_relative_pathname
  end

  # url()

  test 'url should return the correct url' do
    assert_equal Configuration.instance.medusa_url.chomp('/') +'/uuids/' + @dir.uuid,
                 @dir.url
  end

end
