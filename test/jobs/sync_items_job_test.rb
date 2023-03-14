require 'test_helper'

class SyncItemsJobTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
  end

  # perform()

  test 'perform() should sync items' do
    col = collections(:compound_object)
    col.items.destroy_all

    SyncItemsJob.perform_now(collection:  col,
                             ingest_mode: MedusaIngester::IngestMode::CREATE_ONLY,
                             options:     {})

    assert_equal 5, col.items.count
  end

end
