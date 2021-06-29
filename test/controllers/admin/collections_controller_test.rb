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
