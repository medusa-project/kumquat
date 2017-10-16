require 'test_helper'

class PropagatePropertiesToChildrenJobTest < ActiveSupport::TestCase

  # perform()

  ##
  # This is a minimal test that perform() returns. Testing of the actual
  # propagation is done in the test of Item.
  #
  test 'perform() should return' do
    item = items(:illini_union_dir1_dir1_file1)
    PropagatePropertiesToChildrenJob.perform_now(item.repository_id)
  end

end
