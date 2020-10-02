require 'test_helper'

class SyncItemsJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform() should sync items' do
    col = collections(:compound_object)
    col.items.destroy_all

    SyncItemsJob.perform_now(col.repository_id,
                             MedusaIngester::IngestMode::CREATE_ONLY, {})

    assert_equal 5, col.items.count
  end

end
