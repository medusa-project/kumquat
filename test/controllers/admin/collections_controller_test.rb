require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @collection = collections(:compound_object)
  end

  # show()

  test 'show() returns HTTP 200' do
    user = users(:admin)
    sign_in_as(user)

    get admin_collection_path(@collection)
    assert_response :ok
  end

  # unwatch()

  test 'unwatch() unassigns the current user from watching the collection' do
    user = users(:admin)
    sign_in_as(user)

    user.watches.build(collection: @collection)
    user.save!

    patch admin_collection_unwatch_path(@collection)

    user.reload
    assert_equal 0, user.watches.length
    assert_redirected_to admin_collection_path(@collection)
  end

  # update()

  test 'update() updates watches' do
    user = users(:admin)
    sign_in_as(user)

    # add a non-email watch to ensure it doesn't get deleted
    @collection.watches.build(user: users(:admin))
    @collection.save!

    patch admin_collection_path(@collection), {
      xhr: true,
      params: {
        watches: [
          { email: 'sam@example.org' },
          { email: 'jane@example.org' },
          { email: 'bill@example.org' }
        ]
      }
    }
    assert_response :ok

    @collection.reload
    assert_equal 4, @collection.watches.length
    assert_not_nil @collection.watches.find{ |w| w.user == user }
    assert_not_nil @collection.watches.find{ |w| w.email == 'bill@example.org' }
    assert_not_nil @collection.watches.find{ |w| w.email == 'jane@example.org' }
    assert_not_nil @collection.watches.find{ |w| w.email == 'sam@example.org' }
  end

  # watch()

  test 'watch() assigns the current user to watch the collection' do
    user = users(:admin)
    sign_in_as(user)

    assert_equal 0, user.watches.length

    patch admin_collection_watch_path(@collection)

    user.reload
    assert_equal @collection, user.watches.first.collection
    assert_redirected_to admin_collection_path(@collection)
  end

end
