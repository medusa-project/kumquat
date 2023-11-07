require 'test_helper'

class CreatePdfJobTest < ActiveSupport::TestCase

  setup do
    @item     = items(:compound_object_1002)
    @download = Download.create

    setup_elasticsearch
    Item.reindex_all
    refresh_elasticsearch
  end

  teardown do
    @download.destroy!
  end

  # perform()

  test 'perform() should assemble the expected PDF' do
    CreatePdfJob.perform_now(item:                     @item,
                             include_private_binaries: false,
                             download:                 @download)

    client   = KumquatS3Client.instance
    response = client.head_object(bucket: KumquatS3Client::BUCKET,
                                  key:    @download.object_key)
    assert response.content_length > 1000
  end

  test 'perform() should update the download object' do
    CreatePdfJob.perform_now(item:                     @item,
                             include_private_binaries: false,
                             download:                 @download)
    @download.task.reload
    assert_equal Task::Status::SUCCEEDED, @download.task.status
  end

end
