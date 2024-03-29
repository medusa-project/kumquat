require 'test_helper'

class DownloadAllItemsTsvJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create

    setup_opensearch
    Item.reindex_all
    refresh_opensearch
  end

  teardown do
    @download.destroy!
  end

  # perform()

  test 'perform() should assemble the expected zip file' do
    DownloadAllItemsTsvJob.perform_now(download: @download,
                                       user:     users(:medusa_admin))
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
    DownloadAllItemsTsvJob.perform_now(download: @download,
                                       user:     users(:medusa_admin))
    @download.reload
    assert_equal Task::Status::SUCCEEDED, @download.task.status
  end

end
