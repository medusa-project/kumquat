require 'test_helper'

class PurgeItemsJobTest < ActiveSupport::TestCase

  setup do
    setup_opensearch
  end

  # perform()

  test 'perform() should work properly' do
    col = collections(:free_form)
    assert col.items.count > 0
    PurgeItemsJob.perform_now(collection: col)
    assert_equal 0, col.items.count
  end

end
