require 'test_helper'

class PropagatePropertiesToItemsJobTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:illini_union)
    @collection.reindex
    @collection.items.each(&:reindex)
    sleep 2
  end

  # perform()

  ##
  # This is a minimal test that perform() returns. Testing of the actual
  # propagation is done in the test of Collection.
  #
  test 'perform() should return' do
    PropagatePropertiesToItemsJob.perform_now(@collection.repository_id)
  end

end
