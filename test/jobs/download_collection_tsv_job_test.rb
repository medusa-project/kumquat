require 'test_helper'

class DownloadCollectionTsvJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create
  end

  teardown do
    @download.destroy!
  end

  # perform()

  test 'perform() should assemble the expected TSV file' do
    DownloadCollectionTsvJob.perform_now(collection:       collections(:compound_object),
                                         download:         @download,
                                         only_undescribed: false)

    client   = KumquatS3Client.instance
    response = client.head_object(bucket: KumquatS3Client::BUCKET,
                                  key:    @download.object_key)
    assert response.content_length > 0
  end

  test 'perform() should update the download object' do
    DownloadCollectionTsvJob.perform_now(collection:       collections(:compound_object),
                                         download:         @download,
                                         only_undescribed: false)
    assert_equal Task::Status::SUCCEEDED, @download.task.status
  end

end
