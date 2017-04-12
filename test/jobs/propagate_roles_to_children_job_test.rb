require 'test_helper'

class PropagateRolesToChildrenJobTest < ActiveSupport::TestCase

  # perform()

  ##
  # This is a minimal test that perform() returns. Testing of the actual role
  # propagation is done in the test of Item.
  #
  test 'perform() should return' do
    item = items(:iptc_item)
    PropagateRolesToChildrenJob.perform_now(item.repository_id)
  end

end
