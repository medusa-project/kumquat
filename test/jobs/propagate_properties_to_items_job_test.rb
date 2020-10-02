require 'test_helper'

class PropagatePropertiesToItemsJobTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:free_form)
    @collection.reindex
    @collection.items.each(&:reindex)
    refresh_elasticsearch
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
