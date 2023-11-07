require 'test_helper'

class DownloadItemsTsvJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create
  end

  teardown do
    @download.destroy!
  end

  # perform()

  test 'perform() should assemble the expected TSV file' do
    DownloadItemsTsvJob.perform_now(collection:       collections(:compound_object),
                                    download:         @download,
                                    only_undescribed: false)

    client   = KumquatS3Client.instance
    response = client.head_object(bucket: KumquatS3Client::BUCKET,
                                  key:    @download.object_key)
    assert response.content_length > 0
  end

  test 'perform() should update the download object' do
    DownloadItemsTsvJob.perform_now(collection:       collections(:compound_object),
                                    download:         @download,
                                    only_undescribed: false)
    @download.task.reload
    assert_equal Task::Status::SUCCEEDED, @download.task.status
  end

end
