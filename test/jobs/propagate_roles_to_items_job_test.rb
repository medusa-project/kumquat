require 'test_helper'

class PropagateRolesToItemsJobTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:illini_union)
    @collection.reindex
    @collection.items.each { |it| it.reindex }
    sleep 2
  end

  # perform()

  ##
  # This is a minimal test that perform() returns. Testing of the actual role
  # propagation is done in the test of Collection.
  #
  test 'perform() should return' do
    PropagateRolesToItemsJob.perform_now(@collection.repository_id)
  end

end
