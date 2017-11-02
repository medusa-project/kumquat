require 'test_helper'

class UnpublishItemsJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform() should unpublish items' do
    item = items(:sanborn_obj1_page1)
    assert item.published

    UnpublishItemsJob.perform_now([item])

    item.reload
    assert !item.published
  end

end
