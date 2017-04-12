require 'test_helper'

class SyncItemsJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform() should sync items' do
    col = collections(:olin) # This is the smallest collection I know of.
    col.items.destroy_all

    SyncItemsJob.perform_now(col.repository_id,
                             MedusaIngester::IngestMode::CREATE_ONLY, {})

    assert col.items.count > 0
  end

end
