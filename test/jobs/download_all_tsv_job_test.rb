require 'test_helper'

class DownloadAllTsvJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create

    setup_elasticsearch
    Item.reindex_all
    refresh_elasticsearch
  end

  teardown do
    @download.destroy!
  end

  # perform()

  test 'perform() should assemble the expected zip file' do
    DownloadAllTsvJob.perform_now(download: @download)
    Dir.mktmpdir do |tmpdir|
      zip_path = File.join(tmpdir, "file.zip")
      client   = KumquatS3Client.instance
      client.get_object(bucket:          KumquatS3Client::BUCKET,
                        key:             @download.object_key,
                        response_target: zip_path)

      `unzip "#{zip_path}" -d #{tmpdir}`
      assert Dir.glob("#{tmpdir}/*").length > 0
    end
  end

  test 'perform() should update the download object' do
    DownloadAllTsvJob.perform_now(download: @download)
    assert_equal Task::Status::SUCCEEDED, @download.task.status
  end

end
