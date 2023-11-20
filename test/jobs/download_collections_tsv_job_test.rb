require 'test_helper'

class DownloadCollectionsTsvJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create
  end

  teardown do
    @download.destroy!
  end

  # perform()

  test 'perform() should assemble the expected TSV file' do
    collection_ids = [collections(:compound_object)].map(&:id)
    DownloadCollectionsTsvJob.perform_now(collection_ids: collection_ids,
                                          download:       @download,
                                          user:           users(:medusa_admin))

    client   = KumquatS3Client.instance
    response = client.head_object(bucket: KumquatS3Client::BUCKET,
                                  key:    @download.object_key)
    assert response.content_length > 0
  end

  test 'perform() should update the download object' do
    collection_ids = [collections(:compound_object)].map(&:id)
    DownloadCollectionsTsvJob.perform_now(collection_ids: collection_ids,
                                          download:       @download,
                                          user:           users(:medusa_admin))
    @download.reload
    assert_equal Task::Status::SUCCEEDED, @download.task.status
  end

end
