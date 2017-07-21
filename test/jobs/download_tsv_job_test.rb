require 'test_helper'

class DownloadTsvJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create
  end

  teardown do
    File.delete(@download.pathname)
  end

  # perform()

  test 'perform() should assemble the expected TSV file' do
    DownloadTsvJob.perform_now(collections(:sanborn), @download, false)
    assert File.size(@download.pathname) > 0
  end

  test 'perform() should update the download object' do
    DownloadTsvJob.perform_now(collections(:sanborn), @download, false)
    assert_equal Task::Status::SUCCEEDED, @download.task.status
    assert File.exists?(@download.pathname)
  end

end
