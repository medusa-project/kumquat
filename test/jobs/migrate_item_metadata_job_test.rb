require 'test_helper'

class MigrateItemMetadataJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform() should invoke Collection.migrate_item_elements()' do
    col = collections(:collection1)
    assert col.items.count > 0

    src_element_name = 'bogus'
    dest_element_name = 'bogus2'

    assert_raises ArgumentError do
      MigrateItemMetadataJob.perform_now(col.repository_id, src_element_name,
                                         dest_element_name)
    end
  end

end
