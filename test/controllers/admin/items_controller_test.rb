require 'test_helper'

module Admin

  class ItemsControllerTest < ActionDispatch::IntegrationTest

    setup do
      @item       = items(:compound_object_1002)
      @collection = @item.collection
      setup_elasticsearch
      sign_out
    end

    # add_items_to_item_set()

    test "add_items_to_item_set() redirects to sign-in page for signed-out
    users" do
      post admin_collection_items_add_items_to_item_set_path(@collection)
      assert_redirected_to signin_path
    end

    test "add_items_to_item_set() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_items_add_items_to_item_set_path(@collection)
      assert_response :forbidden
    end

    test "add_items_to_item_set() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_items_add_items_to_item_set_path(@collection)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    # add_query_to_item_set()

    test "add_query_to_item_set() redirects to sign-in page for signed-out
    users" do
      post admin_collection_items_add_query_to_item_set_path(@collection)
      assert_redirected_to signin_path
    end

    test "add_query_to_item_set() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_items_add_query_to_item_set_path(@collection)
      assert_response :forbidden
    end

    test "add_query_to_item_set() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_items_add_query_to_item_set_path(@collection),
           params: {
             item_set: item_sets(:one).id
           }
      assert_redirected_to admin_collection_items_path(@collection)
    end

    # batch_change_metadata()

    test "batch_change_metadata() redirects to sign-in page for signed-out
    users" do
      post admin_collection_items_batch_change_metadata_path(@collection)
      assert_redirected_to signin_path
    end

    test "batch_change_metadata() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_items_batch_change_metadata_path(@collection)
      assert_response :forbidden
    end

    test "batch_change_metadata() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_items_batch_change_metadata_path(@collection),
           params: {
             item_ids: [
               Item.all.first.repository_id
             ],
             element: "title",
             replace_values: [
               {
                 string: "cats",
                 uri:    "http://example.org/cats"
               }
             ]
           }
      assert_redirected_to admin_collection_items_path(@collection)
    end

    # disable_full_text_search()

    test "disable_full_text_search() redirects to sign-in page for signed-out
    users" do
      patch admin_collection_items_disable_full_text_search_path(@collection)
      assert_redirected_to signin_path
    end

    test "disable_full_text_search() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collection_items_disable_full_text_search_path(@collection)
      assert_response :forbidden
    end

    test "disable_full_text_search() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_collection_items_disable_full_text_search_path(@collection)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    test "disable_full_text_search() disables full-text search for the given
    items when IDs are provided" do
      sign_in_as(users(:medusa_admin))

      items = [
        items(:compound_object_1001),
        items(:compound_object_1002)
      ]
      Item.transaction do
        items.each do |item|
          item.update!(expose_full_text_search: true)
        end
      end
      refresh_elasticsearch

      ids = items.map(&:repository_id)
      patch admin_collection_items_disable_full_text_search_path(items[0].collection),
            params: {
              'ids[]': ids
            }

      items.each do |item|
        item.reload
        assert !item.expose_full_text_search
      end
    end

    test 'disable_full_text_search() disables full-text search for all items in a
    collection when IDs are not provided' do
      sign_in_as(users(:medusa_admin))

      Item.transaction do
        @item.collection.items.each do |item|
          item.update!(expose_full_text_search: true)
        end
      end
      refresh_elasticsearch

      patch admin_collection_items_disable_full_text_search_path(@item.collection)

      @item.collection.items.each do |item|
        item.reload
        assert !item.expose_full_text_search
      end
    end

    # edit_access()

    test "edit_access() redirects to sign-in page for signed-out users" do
      get admin_collection_item_edit_access_path(@item.collection, @item),
          xhr: true
      assert_redirected_to signin_path
    end

    test "edit_access() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_item_edit_access_path(@item.collection, @item),
          xhr: true
      assert_response :forbidden
    end

    test "edit_access() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_item_edit_access_path(@item.collection, @item),
          xhr: true
      assert_response :ok
    end

    # edit_all()

    test "edit_all() redirects to sign-in page for signed-out users" do
      get admin_collection_items_edit_path(@collection)
      assert_redirected_to signin_path
    end

    test "edit_all() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_items_edit_path(@collection)
      assert_response :forbidden
    end

    test "edit_all() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_items_edit_path(@collection)
      assert_response :ok
    end

    # edit_info()

    test "edit_info() redirects to sign-in page for signed-out users" do
      get admin_collection_item_edit_info_path(@item.collection, @item),
          xhr: true
      assert_redirected_to signin_path
    end

    test "edit_info() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_item_edit_info_path(@item.collection, @item),
          xhr: true
      assert_response :forbidden
    end

    test "edit_info() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_item_edit_info_path(@item.collection, @item),
          xhr: true
      assert_response :ok
    end

    # edit_metadata()

    test "edit_metadata() redirects to sign-in page for signed-out users" do
      get admin_collection_item_edit_metadata_path(@item.collection, @item),
          xhr: true
      assert_redirected_to signin_path
    end

    test "edit_metadata() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_item_edit_metadata_path(@item.collection, @item),
          xhr: true
      assert_response :forbidden
    end

    test "edit_metadata() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_item_edit_metadata_path(@item.collection, @item),
          xhr: true
      assert_response :ok
    end

    # edit_representation()

    test "edit_representation() redirects to sign-in page for signed-out users" do
      get admin_collection_item_edit_representation_path(@item.collection, @item),
          xhr: true
      assert_redirected_to signin_path
    end

    test "edit_representation() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_item_edit_representation_path(@item.collection, @item),
          xhr: true
      assert_response :forbidden
    end

    test "edit_representation() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_item_edit_representation_path(@item.collection, @item),
          xhr: true
      assert_response :ok
    end

    # enable_full_text_search()

    test "enable_full_text_search() redirects to sign-in page for signed-out users" do
      patch admin_collection_items_enable_full_text_search_path(@collection)
      assert_redirected_to signin_path
    end

    test "enable_full_text_search() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collection_items_enable_full_text_search_path(@collection)
      assert_response :forbidden
    end

    test "enable_full_text_search() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_collection_items_enable_full_text_search_path(@collection)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    test "enable_full_text_search() enables full-text search for the given items
    when IDs are provided" do
      sign_in_as(users(:medusa_admin))

      items = [
        items(:compound_object_1001),
        items(:compound_object_1002)
      ]
      Item.transaction do
        items.each do |item|
          item.update!(expose_full_text_search: false)
        end
      end
      refresh_elasticsearch

      ids = items.map(&:repository_id)
      patch admin_collection_items_enable_full_text_search_path(items[0].collection),
            params: {
              'ids[]': ids
            }

      items.each do |item|
        item.reload
        assert item.expose_full_text_search
      end
    end

    test "enable_full_text_search() enables full-text search for all items in a
    collection when IDs are not provided" do
      sign_in_as(users(:medusa_admin))

      Item.transaction do
        @item.collection.items.each do |item|
          item.update!(expose_full_text_search: false)
        end
      end
      refresh_elasticsearch

      patch admin_collection_items_enable_full_text_search_path(@item.collection)

      @item.collection.items.each do |item|
        item.reload
        assert item.expose_full_text_search
      end
    end

    # index()

    test "index() redirects to sign-in page for signed-out users" do
      get admin_collection_items_path(@collection)
      assert_redirected_to signin_path
    end

    test "index() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_items_path(@collection)
      assert_response :forbidden
    end

    test "index() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_items_path(@collection)
      assert_response :ok
    end

    # import()

    test "import() redirects to sign-in page for signed-out users" do
      post admin_collection_items_import_path(@collection)
      assert_redirected_to signin_path
    end

    test "import() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_items_import_path(@collection)
      assert_response :forbidden
    end

    test "import() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_items_import_path(@collection, format: :tsv)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    # migrate_metadata()

    test "migrate_metadata() redirects to sign-in page for signed-out users" do
      post admin_collection_items_migrate_metadata_path(@collection)
      assert_redirected_to signin_path
    end

    test "migrate_metadata() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_items_migrate_metadata_path(@collection)
      assert_response :forbidden
    end

    test "migrate_metadata() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_items_migrate_metadata_path(@collection)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    # publicize_child_binaries()

    test "publicize_child_binaries() redirects to sign-in page for signed-out users" do
      post admin_collection_item_publicize_child_binaries_path(@item.collection, @item)
      assert_redirected_to signin_path
    end

    test "publicize_child_binaries() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_item_publicize_child_binaries_path(@item.collection, @item)
      assert_response :forbidden
    end

    test "publicize_child_binaries() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_item_publicize_child_binaries_path(@item.collection, @item)
      assert_redirected_to admin_collection_item_path(@item.collection, @item)
    end

    test "publicize_child_binaries() publicizes all child binaries" do
      sign_in_as(users(:medusa_admin))

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

    # publish()

    test "publish() redirects to sign-in page for signed-out users" do
      patch admin_collection_items_publish_path(@collection)
      assert_redirected_to signin_path
    end

    test "publish() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collection_items_publish_path(@collection)
      assert_response :forbidden
    end

    test "publish() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_collection_items_publish_path(@collection)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    test 'publish() publishes the given items when IDs are provided' do
      sign_in_as(users(:medusa_admin))

      items = [
        items(:compound_object_1001),
        items(:compound_object_1002)
      ]
      Item.transaction do
        items.each do |item|
          item.update!(published: false)
        end
      end
      refresh_elasticsearch

      ids = items.map(&:repository_id)
      patch admin_collection_items_publish_path(items[0].collection),
            params: {
              'ids[]': ids
            }

      items.each do |item|
        item.reload
        assert item.published
      end
    end

    test 'publish() publishes all items in a collection when IDs are not provided' do
      sign_in_as(users(:medusa_admin))

      Item.transaction do
        @item.collection.items.each do |item|
          item.update!(published: false)
        end
      end
      refresh_elasticsearch

      patch admin_collection_items_publish_path(@item.collection)

      @item.collection.items.each do |item|
        item.reload
        assert item.published
      end
    end

    # purge_cached_images()

    test "purge_cached_images() redirects to sign-in page for signed-out users" do
      post admin_collection_item_purge_cached_images_path(@item.collection, @item)
      assert_redirected_to signin_path
    end

    test "purge_cached_images() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_item_purge_cached_images_path(@item.collection, @item)
      assert_response :forbidden
    end

    test "purge_cached_images() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_item_purge_cached_images_path(@item.collection, @item)
      assert_redirected_to admin_collection_item_path(@item.collection, @item)
    end

    # replace_metadata()

    test "replace_metadata() redirects to sign-in page for signed-out users" do
      post admin_collection_items_replace_metadata_path(@collection)
      assert_redirected_to signin_path
    end

    test "replace_metadata() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_items_replace_metadata_path(@collection)
      assert_response :forbidden
    end

    test "replace_metadata() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_items_replace_metadata_path(@collection)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    # run_ocr()

    test "run_ocr() redirects to sign-in page for signed-out users" do
      patch admin_collection_items_run_ocr_path(@collection)
      assert_redirected_to signin_path
    end

    test "run_ocr() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collection_items_run_ocr_path(@collection)
      assert_response :forbidden
    end

    test "run_ocr() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_collection_items_run_ocr_path(@collection)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    # show()

    test "show() redirects to sign-in page for signed-out users" do
      get admin_collection_item_path(@item.collection, @item)
      assert_redirected_to signin_path
    end

    test "show() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_item_path(@item.collection, @item)
      assert_response :forbidden
    end

    test "show() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_item_path(@item.collection, @item)
      assert_response :ok
    end

    # sync()

    test "sync() redirects to sign-in page for signed-out users" do
      post admin_collection_items_sync_path(@collection)
      assert_redirected_to signin_path
    end

    test "sync() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_items_sync_path(@collection)
      assert_response :forbidden
    end

    test "sync() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_items_sync_path(@collection)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    # unpublicize_child_binaries()

    test "unpublicize_child_binaries() redirects to sign-in page for signed-out
    users" do
      post admin_collection_item_unpublicize_child_binaries_path(@item.collection, @item)
      assert_redirected_to signin_path
    end

    test "unpublicize_child_binaries() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_item_unpublicize_child_binaries_path(@item.collection, @item)
      assert_response :forbidden
    end

    test "unpublicize_child_binaries() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_item_unpublicize_child_binaries_path(@item.collection, @item)
      assert_redirected_to admin_collection_item_path(@item.collection, @item)
    end

    test "unpublicize_child_binaries() unpublicizes all child binaries" do
      sign_in_as(users(:medusa_admin))

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

    test "unpublicize_child_binaries() redirects back upon success" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_item_unpublicize_child_binaries_path(@item.collection, @item)
      assert_redirected_to admin_collection_item_path(@item.collection, @item)
    end

    # unpublish()

    test "unpublish() redirects to sign-in page for signed-out users" do
      patch admin_collection_items_unpublish_path(@collection)
      assert_redirected_to signin_path
    end

    test "unpublish() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collection_items_unpublish_path(@collection)
      assert_response :forbidden
    end

    test "unpublish() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_collection_items_unpublish_path(@collection)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    test "unpublish() unpublishes the given items when IDs are provided" do
      sign_in_as(users(:medusa_admin))

      items = [
        items(:compound_object_1001),
        items(:compound_object_1002)
      ]
      Item.transaction do
        items.each do |item|
          item.update!(published: true)
        end
      end
      refresh_elasticsearch

      ids = items.map(&:repository_id)
      patch admin_collection_items_unpublish_path(items[0].collection),
            params: {
              'ids[]': ids
            }

      items.each do |item|
        item.reload
        assert !item.published
      end
    end

    test "unpublish() unpublishes all items in a collection when IDs are not
    provided" do
      sign_in_as(users(:medusa_admin))

      Item.transaction do
        @item.collection.items.each do |item|
          item.update!(published: true)
        end
      end
      refresh_elasticsearch

      patch admin_collection_items_unpublish_path(@item.collection)

      @item.collection.items.each do |item|
        item.reload
        assert !item.published
      end
    end

    # update()

    test "update() redirects to sign-in page for signed-out users" do
      patch admin_collection_item_path(@item.collection, @item)
      assert_redirected_to signin_path
    end

    test "update() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collection_item_path(@item.collection, @item)
      assert_response :forbidden
    end

    test "update() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_collection_item_path(@item.collection, @item)
      assert_redirected_to admin_collection_item_path(@item.collection, @item)
    end

    # update_all()

    test "update_all() redirects to sign-in page for signed-out users" do
      post admin_collection_items_update_path(@item.collection)
      assert_redirected_to signin_path
    end

    test "update_all() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_items_update_path(@item.collection)
      assert_response :forbidden
    end

    test "update_all() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_items_update_path(@item.collection)
      assert_redirected_to admin_collections_path
    end

  end

end