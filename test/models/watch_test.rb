require "test_helper"

class WatchTest < ActiveSupport::TestCase

  # save()

  test 'save() raises an error for a record with a duplicate collection_id and
  user_id' do
    user       = users(:admin)
    collection = collections(:compound_object)
    Watch.create!(user: user, collection: collection)
    assert_raises ActiveRecord::RecordNotUnique do
      Watch.create!(user: user, collection: collection)
    end
  end

end
