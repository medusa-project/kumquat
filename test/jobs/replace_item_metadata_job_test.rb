require 'test_helper'

class ReplaceItemMetadataJobTest < ActiveSupport::TestCase

  # perform()

  ##
  # This is a minimal test that perform() returns. Testing of the actual role
  # propagation is done in the test of Collection.
  #
  test 'perform() should invoke Collection.replace_item_element_values()' do
    col = collections(:collection1)
    assert col.items.count > 0

    assert_raises ArgumentError do
      ReplaceItemMetadataJob.perform_now(col.repository_id, :contain, 't',
                                         'title', :bogus, 'dogs')
    end
  end

end
