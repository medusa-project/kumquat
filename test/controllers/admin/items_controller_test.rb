require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @item = items(:compound_object_1002)
  end

  # disable_full_text_search()

  test 'disable_full_text_search() disables full-text search for the given
  items when IDs are provided' do
    sign_in_as(users(:admin))

    items = [
      items(:compound_object_1001),
      items(:compound_object_1002)
    ]
    items.each do |item|
      item.update!(expose_full_text_search: true)
    end

    ids = items.map(&:repository_id)
    patch admin_collection_items_disable_full_text_search_path(items[0].collection), {
      params: {
        'ids[]': ids
      }
    }

    items.each do |item|
      item.reload
      assert !item.expose_full_text_search
    end
  end

  test 'disable_full_text_search() disables full-text search for all items in a
  collection when IDs are not provided' do
    sign_in_as(users(:admin))

    @item.collection.items.each do |item|
      item.update!(expose_full_text_search: true)
    end
    patch admin_collection_items_disable_full_text_search_path(@item.collection)

    @item.collection.items.each do |item|
      item.reload
      assert !item.expose_full_text_search
    end
  end

  # enable_full_text_search()

  test 'enable_full_text_search() enables full-text search for the given items
  when IDs are provided' do
    sign_in_as(users(:admin))

    items = [
      items(:compound_object_1001),
      items(:compound_object_1002)
    ]
    items.each do |item|
      item.update!(expose_full_text_search: false)
    end

    ids = items.map(&:repository_id)
    patch admin_collection_items_enable_full_text_search_path(items[0].collection), {
      params: {
        'ids[]': ids
      }
    }

    items.each do |item|
      item.reload
      assert item.expose_full_text_search
    end
  end

  test 'enable_full_text_search() enables full-text search for all items in a
  collection when IDs are not provided' do
    sign_in_as(users(:admin))

    @item.collection.items.each do |item|
      item.update!(expose_full_text_search: false)
    end
    patch admin_collection_items_enable_full_text_search_path(@item.collection)

    @item.collection.items.each do |item|
      item.reload
      assert item.expose_full_text_search
    end
  end

  # publicize_child_binaries()

  test "publicize_child_binaries() redirects to sign-in page for signed-out users" do
    post admin_collection_item_publicize_child_binaries_path(@item.collection, @item)
    assert_redirected_to signin_path
  end

  test 'publicize_child_binaries() publicizes all child binaries' do
    sign_in_as(users(:admin))

    # unpublicize all child items' binaries
    binaries = @item.items.map{ |child| child.binaries }.flatten
    binaries.each{ |binary| binary.update!(public: false) }

    post admin_collection_item_publicize_child_binaries_path(@item.collection, @item)

    # test that they have been publicized
    binaries.each do |binary|
      binary.reload
      assert binary.public
    end
  end

  test 'publicize_child_binaries() redirects back upon success' do
    sign_in_as(users(:admin))
    post admin_collection_item_publicize_child_binaries_path(@item.collection, @item)
    assert_redirected_to admin_collection_item_path(@item.collection, @item)
  end

  # publish()

  test 'publish() publishes the given items when IDs are provided' do
    sign_in_as(users(:admin))

    items = [
      items(:compound_object_1001),
      items(:compound_object_1002)
    ]
    items.each do |item|
      item.update!(published: false)
    end

    ids = items.map(&:repository_id)
    patch admin_collection_items_publish_path(items[0].collection), {
      params: {
        'ids[]': ids
      }
    }

    items.each do |item|
      item.reload
      assert item.published
    end
  end

  test 'publish() publishes all items in a collection when IDs are not provided' do
    sign_in_as(users(:admin))

    @item.collection.items.each do |item|
      item.update!(published: false)
    end
    patch admin_collection_items_publish_path(@item.collection)

    @item.collection.items.each do |item|
      item.reload
      assert item.published
    end
  end

  # unpublicize_child_binaries()

  test "unpublicize_child_binaries() redirects to sign-in page for signed-out users" do
    post admin_collection_item_unpublicize_child_binaries_path(@item.collection, @item)
    assert_redirected_to signin_path
  end

  test 'unpublicize_child_binaries() unpublicizes all child binaries' do
    sign_in_as(users(:admin))

    # verify that all child items' binaries are public
    binaries = @item.items.map{ |child| child.binaries }.flatten
    binaries.each{ |binary| assert binary.public }

    post admin_collection_item_unpublicize_child_binaries_path(@item.collection, @item)

    # test that they have been unpublicized
    binaries.each do |binary|
      binary.reload
      assert !binary.public
    end
  end

  test 'unpublicize_child_binaries() redirects back upon success' do
    sign_in_as(users(:admin))
    post admin_collection_item_unpublicize_child_binaries_path(@item.collection, @item)
    assert_redirected_to admin_collection_item_path(@item.collection, @item)
  end

  # unpublish()

  test 'unpublish() unpublishes the given items when IDs are provided' do
    sign_in_as(users(:admin))

    items = [
      items(:compound_object_1001),
      items(:compound_object_1002)
    ]
    items.each do |item|
      item.update!(published: true)
    end

    ids = items.map(&:repository_id)
    patch admin_collection_items_unpublish_path(items[0].collection), {
      params: {
        'ids[]': ids
      }
    }

    items.each do |item|
      item.reload
      assert !item.published
    end
  end

  test 'unpublish() unpublishes all items in a collection when IDs are not provided' do
    sign_in_as(users(:admin))

    @item.collection.items.each do |item|
      item.update!(published: true)
    end
    patch admin_collection_items_unpublish_path(@item.collection)

    @item.collection.items.each do |item|
      item.reload
      assert !item.published
    end
  end

end

