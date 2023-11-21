require 'test_helper'

module Admin

  class CollectionsControllerTest < ActionDispatch::IntegrationTest

    setup do
      @collection = collections(:compound_object)
      sign_out
    end

    # delete_items()

    test "delete_items() redirects to sign-in page for signed-out users" do
      delete admin_collection_delete_items_path(@collection)
      assert_redirected_to signin_path
    end

    test "delete_items() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      delete admin_collection_delete_items_path(@collection)
      assert_response :forbidden
    end

    test "delete_items() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      delete admin_collection_delete_items_path(@collection)
      assert_redirected_to admin_collection_items_path(@collection)
    end

    # edit_access()

    test "edit_access() redirects to sign-in page for signed-out users" do
      get admin_collection_edit_access_path(@collection), xhr: true
      assert_redirected_to signin_path
    end

    test "edit_access() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_edit_access_path(@collection), xhr: true
      assert_response :forbidden
    end

    test "edit_access() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_edit_access_path(@collection), xhr: true
      assert_response :ok
    end

    # edit_info()

    test "edit_info() redirects to sign-in page for signed-out users" do
      get admin_collection_edit_info_path(@collection), xhr: true
      assert_redirected_to signin_path
    end

    test "edit_info() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_edit_info_path(@collection), xhr: true
      assert_response :forbidden
    end

    test "edit_info() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_edit_info_path(@collection), xhr: true
      assert_response :ok
    end

    # edit_email_watchers()

    test "edit_email_watchers() redirects to sign-in page for signed-out users" do
      get admin_collection_edit_email_watchers_path(@collection), xhr: true
      assert_redirected_to signin_path
    end

    test "edit_email_watchers() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_edit_email_watchers_path(@collection), xhr: true
      assert_response :forbidden
    end

    test "edit_email_watchers() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_edit_email_watchers_path(@collection), xhr: true
      assert_response :ok
    end

    # edit_representation()

    test "edit_representation() redirects to sign-in page for signed-out users" do
      get admin_collection_edit_representation_path(@collection), xhr: true
      assert_redirected_to signin_path
    end

    test "edit_representation() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_edit_representation_path(@collection), xhr: true
      assert_response :forbidden
    end

    test "edit_representation() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get admin_collection_edit_representation_path(@collection), xhr: true
      assert_response :ok
    end

    # index()

    test "index() redirects to sign-in page for signed-out users" do
      get admin_collections_path
      assert_redirected_to signin_path
    end

    test "index() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collections_path
      assert_response :forbidden
    end

    test "index() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_user))
      get admin_collections_path
      assert_response :ok
    end

    test "index() returns HTML" do
      sign_in_as(users(:medusa_user))
      get admin_collections_path
      assert response.content_type.start_with?("text/html")
    end

    test "index() returns JS" do
      sign_in_as(users(:medusa_user))
      get admin_collections_path, xhr: true
      assert response.content_type.start_with?("text/javascript")
    end

    test "index() returns TSV" do
      sign_in_as(users(:medusa_user))
      get admin_collections_path(format: :tsv)
      assert response.content_type.start_with?("text/tab-separated-values")
    end

    # items()

    test "items() redirects to sign-in page for signed-out users" do
      get admin_collection_items_path(@collection)
      assert_redirected_to signin_path
    end

    test "items() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_items_path(@collection)
      assert_response :forbidden
    end

    test "items() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_user))
      get admin_collection_items_path(@collection)
      assert_response :ok
    end

    # purge_cached_images()

    test "purge_cached_images() redirects to sign-in page for signed-out users" do
      post admin_collection_purge_cached_images_path(@collection)
      assert_redirected_to signin_path
    end

    test "purge_cached_images() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_purge_cached_images_path(@collection)
      assert_response :forbidden
    end

    test "purge_cached_images() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_purge_cached_images_path(@collection)
      assert_redirected_to admin_collection_path(@collection)
    end

    # show()

    test "show() redirects to sign-in page for signed-out users" do
      get admin_collection_path(@collection)
      assert_redirected_to signin_path
    end

    test "show() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_path(@collection)
      assert_response :forbidden
    end

    test "show() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_user))
      get admin_collection_path(@collection)
      assert_response :ok
    end

    # statistics()

    test "statistics() redirects to sign-in page for signed-out users" do
      get admin_collection_statistics_path(@collection)
      assert_redirected_to signin_path
    end

    test "statistics() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_statistics_path(@collection)
      assert_response :forbidden
    end

    test "statistics() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_user))
      get admin_collection_statistics_path(@collection)
      assert_response :ok
    end

    # sync()

    test "sync() redirects to sign-in page for signed-out users" do
      patch admin_collections_sync_path
      assert_redirected_to signin_path
    end

    test "sync() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collections_sync_path
      assert_response :forbidden
    end

    test "sync() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_collections_sync_path
      assert_redirected_to admin_collections_path
    end

    # unwatch()

    test "unwatch() redirects to sign-in page for signed-out users" do
      patch admin_collection_unwatch_path(@collection)
      assert_redirected_to signin_path
    end

    test "unwatch() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collection_unwatch_path(@collection)
      assert_response :forbidden
    end

    test "unwatch() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_collection_unwatch_path(@collection)
      assert_redirected_to admin_collection_path(@collection)
    end

    test "unwatch() removes the current user as a watcher" do
      user = users(:medusa_admin)
      sign_in_as(user)

      user.watches.build(collection: @collection)
      user.save!

      patch admin_collection_unwatch_path(@collection)

      user.reload
      assert_equal 0, user.watches.length
      assert_redirected_to admin_collection_path(@collection)
    end

    # update()

    test "update() redirects to sign-in page for signed-out users" do
      patch admin_collection_path(@collection)
      assert_redirected_to signin_path
    end

    test "update() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collection_path(@collection)
      assert_response :forbidden
    end

    test "update() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_collection_path(@collection),
            params: {
              watches: [
                { email: 'sam@example.org' },
                { email: 'jane@example.org' },
                { email: 'bill@example.org' }
              ]
            }
      assert_redirected_to admin_collection_path(@collection)
    end

    test "update() updates watches" do
      user = users(:medusa_admin)
      sign_in_as(user)

      # add a non-email watch to ensure it doesn't get deleted
      @collection.watches.build(user: users(:medusa_admin))
      @collection.save!

      patch admin_collection_path(@collection),
            params: {
              watches: [
                { email: 'sam@example.org' },
                { email: 'jane@example.org' },
                { email: 'bill@example.org' }
              ]
            }

      @collection.reload
      assert_equal 4, @collection.watches.length
      assert_not_nil @collection.watches.find{ |w| w.user == user }
      assert_not_nil @collection.watches.find{ |w| w.email == 'bill@example.org' }
      assert_not_nil @collection.watches.find{ |w| w.email == 'jane@example.org' }
      assert_not_nil @collection.watches.find{ |w| w.email == 'sam@example.org' }
    end

    # watch()

    test "watch() redirects to sign-in page for signed-out users" do
      patch admin_collection_watch_path(@collection)
      assert_redirected_to signin_path
    end

    test "watch() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collection_watch_path(@collection)
      assert_response :forbidden
    end

    test "watch() redirects for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_collection_watch_path(@collection)
      assert_redirected_to admin_collection_path(@collection)
    end

    test "watch() adds the current user as a watcher" do
      user = users(:medusa_admin)
      sign_in_as(user)

      assert_equal 0, user.watches.length

      patch admin_collection_watch_path(@collection)

      user.reload
      assert_equal @collection, user.watches.first.collection
      assert_redirected_to admin_collection_path(@collection)
    end

  end

end
