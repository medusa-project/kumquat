require 'test_helper'

class DownloadAllTsvJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create

    setup_elasticsearch
    Item.reindex_all
    refresh_elasticsearch
  end

  teardown do
    File.delete(@download.pathname) if @download.pathname
  end

  # perform()

  test 'perform() should assemble the expected zip file' do
    DownloadAllTsvJob.perform_now(@download)
    Dir.mktmpdir do |tmpdir|
      `unzip "#{@download.pathname}" -d #{tmpdir}`
      assert Dir.glob("#{tmpdir}/*").length > 0
    end
  end

  test 'perform() should update the download object' do
    DownloadAllTsvJob.perform_now(@download)
    assert_equal Task::Status::SUCCEEDED, @download.task.status
    assert File.exists?(@download.pathname)
  end

end
