require "test_helper"

class WatchTest < ActiveSupport::TestCase

  # save()

  test 'save() raises an error for a record with a duplicate collection_id and
  user_id' do
    user       = users(:medusa_admin)
    collection = collections(:compound_object)
    Watch.create!(user: user, collection: collection)
    assert_raises ActiveRecord::RecordNotUnique do
      Watch.create!(user: user, collection: collection)
    end
  end

  # valid?()

  test 'valid?() returns false for a record with no collection_id' do
    watch = Watch.new(user: users(:medusa_admin))
    assert !watch.valid?
  end

  test 'valid?() returns false for a record with neither an email nor a user_id' do
    watch = Watch.new(collection: collections(:compound_object))
    assert !watch.valid?
  end

  test 'valid?() returns false for a record with both an email and a user_id' do
    watch = Watch.new(user:       users(:medusa_admin),
                      email:      "somebody@example.org",
                      collection: collections(:compound_object))
    assert !watch.valid?
  end

  test 'valid?() returns true for a record with an email and a collection_id' do
    watch = Watch.new(email:      "somebody@example.org",
                      collection: collections(:compound_object))
    assert watch.valid?
  end

  test 'valid?() returns true for a record with a user_id and a collection_id' do
    watch = Watch.new(user:       users(:medusa_admin),
                      collection: collections(:compound_object))
    assert watch.valid?
  end

end
