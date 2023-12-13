require 'test_helper'

class UpdateItemsFromEmbeddedMetadataJobTest < ActiveSupport::TestCase

  # perform()

  ##
  # This is a minimal test that perform() returns. Testing of the actual
  # updating happens in the test of ItemUpdater.
  #
  test 'perform() should not crash' do
    UpdateItemsFromEmbeddedMetadataJob.perform_now(collection: collections(:compound_object))
  end

end
