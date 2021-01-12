require 'test_helper'

class SyncCollectionsJobTest < ActiveSupport::TestCase

  # perform()

  # Collection syncing is tested more thoroughly in MedusaIngesterTest. This is
  # just a test that perform() returns.
  test 'perform() adds missing collections' do
    Collection.destroy_all
    SyncCollectionsJob.perform_now
    assert Collection.count >= 5
  end

end
