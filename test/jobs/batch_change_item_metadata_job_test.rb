require 'test_helper'

##
# This is just a basic sanity check; the batch-changing functionality is tested
# more thoroughly in the test of Collection.change_item_element_values().
#
class BatchChangeItemMetadataJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform() should change all matching elements' do
    col = collections(:illini_union)
    assert col.items.count > 0

    element_name = 'title'
    new_values = [
        {
            string: 'some new title',
            uri: 'http://example.org/1'
        },
        {
            string: 'another new title',
            uri: 'http://example.org/2'
        }
    ]

    BatchChangeItemMetadataJob.perform_now(col.repository_id, element_name,
                                           new_values)

    col.items.each do |item|
      titles = item.elements.select{ |e| e.name == 'title' }
      assert_equal new_values.length, titles.length
      new_values.each do |nv|
        assert_equal 1, titles.select{ |e| e.value == nv[:string] and e.uri == nv[:uri] }.length
      end
    end
  end

end
