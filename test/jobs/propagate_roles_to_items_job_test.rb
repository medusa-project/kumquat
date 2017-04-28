require 'test_helper'

class PropagateRolesToItemsJobTest < ActiveSupport::TestCase

  # perform()

  ##
  # This is a minimal test that perform() returns. Testing of the actual role
  # propagation is done in the test of Collection.
  #
  test 'perform() should return' do
    col = collections(:illini_union)
    PropagateRolesToItemsJob.perform_now(col.repository_id)
  end

end
