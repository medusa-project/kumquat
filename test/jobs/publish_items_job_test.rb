require 'test_helper'

class PublishItemsJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform() should publish items' do
    item = items(:sanborn_obj1_page1)
    item.update!(published: false)

    PublishItemsJob.perform_now([item])

    item.reload
    assert item.published
  end

end
