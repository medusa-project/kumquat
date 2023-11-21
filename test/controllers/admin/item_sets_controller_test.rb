require 'test_helper'

module Admin

  class ItemSetsControllerTest < ActionDispatch::IntegrationTest

    setup do
      @item_set   = item_sets(:one)
      @collection = @item_set.collection
      sign_out
    end

    # create()

    test "create() redirects to sign-in page for signed-out users" do
      post admin_collection_item_sets_path(@collection)
      assert_redirected_to signin_path
    end

    test "create() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_collection_item_sets_path(@collection),
           xhr: true,
           params: {
             item_set: {
               name: "test"
             }
           }
      assert_response :forbidden
    end

    test "create() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      post admin_collection_item_sets_path(@collection), xhr: true,
           params: {
             item_set: {
               name: "test"
             }
           }
      assert_response :ok
    end

    # destroy()

    test "destroy() redirects to sign-in page for signed-out users" do
      delete admin_collection_item_set_path(@collection, @item_set)
      assert_redirected_to signin_path
    end

    test "destroy() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      delete admin_collection_item_set_path(@collection, @item_set)
      assert_response :forbidden
    end

    test "destroy() redirects for authorized users" do
      sign_in_as(users(:medusa_super_admin))
      delete admin_collection_item_set_path(@collection, @item_set)
      assert_redirected_to admin_collection_path(@collection)
    end

    # edit()

    test "edit() redirects to sign-in page for signed-out users" do
      get edit_admin_collection_item_set_path(@collection, @item_set), xhr: true
      assert_redirected_to signin_path
    end

    test "edit() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get edit_admin_collection_item_set_path(@collection, @item_set), xhr: true
      assert_response :forbidden
    end

    test "edit() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_super_admin))
      get edit_admin_collection_item_set_path(@collection, @item_set), xhr: true
      assert_response :ok
    end

    # items()

    test "items() redirects to sign-in page for signed-out users" do
      get admin_collection_item_set_items_path(@collection, @item_set)
      assert_redirected_to signin_path
    end

    test "items() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_item_set_items_path(@collection, @item_set)
      assert_response :forbidden
    end

    test "items() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_super_admin))
      get admin_collection_item_set_items_path(@collection, @item_set)
      assert_response :ok
    end

    # new()

    test "new() redirects to sign-in page for signed-out users" do
      get new_admin_collection_item_set_path(@collection)
      assert_redirected_to signin_path
    end

    test "new() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get new_admin_collection_item_set_path(@collection)
      assert_response :forbidden
    end

    test "new() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      get new_admin_collection_item_set_path(@collection)
      assert_response :ok
    end

    # remove_all_items()

    test "remove_all_items() redirects to sign-in page for signed-out users" do
      delete admin_collection_item_set_remove_all_items_path(@collection, @item_set)
      assert_redirected_to signin_path
    end

    test "remove_all_items() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      delete admin_collection_item_set_remove_all_items_path(@collection, @item_set)
      assert_response :forbidden
    end

    test "remove_all_items() redirects for authorized users" do
      sign_in_as(users(:medusa_super_admin))
      delete admin_collection_item_set_remove_all_items_path(@collection, @item_set)
      assert_redirected_to admin_collection_item_set_path(@collection, @item_set)
    end

    # remove_items()

    test "remove_items() redirects to sign-in page for signed-out users" do
      delete admin_collection_item_set_remove_items_path(@collection, @item_set)
      assert_redirected_to signin_path
    end

    test "remove_items() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      delete admin_collection_item_set_remove_items_path(@collection, @item_set)
      assert_response :forbidden
    end

    test "remove_items() redirects for authorized users" do
      sign_in_as(users(:medusa_super_admin))
      delete admin_collection_item_set_remove_items_path(@collection, @item_set)
      assert_redirected_to admin_collection_item_set_path(@collection, @item_set)
    end

    # show()

    test "show() redirects to sign-in page for signed-out users" do
      get admin_collection_item_set_path(@collection, @item_set)
      assert_redirected_to signin_path
    end

    test "show() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_collection_item_set_path(@collection, @item_set)
      assert_response :forbidden
    end

    test "show() returns HTTP 200 for authorized users" do
      setup_elasticsearch
      sign_in_as(users(:medusa_super_admin))
      get admin_collection_item_set_path(@collection, @item_set)
      assert_response :ok
    end

    # update()

    test "update() redirects to sign-in page for signed-out users" do
      patch admin_collection_item_set_path(@collection, @item_set)
      assert_redirected_to signin_path
    end

    test "update() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_collection_item_set_path(@collection, @item_set)
      assert_response :forbidden
    end

    test "update() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_super_admin))
      patch admin_collection_item_set_path(@collection, @item_set),
            xhr: true,
            params: {
              item_set: {
                name: "New Name"
              }
            }
      assert_response :ok
    end

  end

end