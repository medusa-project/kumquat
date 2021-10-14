require 'test_helper'

class DownloadCollectionTsvJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create
  end

  teardown do
    File.delete(@download.pathname)
  end

  # perform()

  test 'perform() should assemble the expected TSV file' do
    DownloadCollectionTsvJob.perform_now(collections(:compound_object), @download, false)
    assert File.size(@download.pathname) > 0
  end

  test 'perform() should update the download object' do
    DownloadCollectionTsvJob.perform_now(collections(:compound_object), @download, false)
    assert_equal Task::Status::SUCCEEDED, @download.task.status
    assert File.exists?(@download.pathname)
  end

end
