require 'test_helper'

class PurgeItemsJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform() should work properly' do
    col = collections(:collection1)
    assert col.items.count > 0
    PurgeItemsJob.perform_now(col.repository_id)
    assert col.items.count == 0
  end

end