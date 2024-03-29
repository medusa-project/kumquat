require 'test_helper'

module Admin

  class BinariesControllerTest < ActionDispatch::IntegrationTest

    setup do
      @binary = binaries(:compound_object_1001_access)
    end

    # edit_access()

    test "edit_access() redirects to sign-in page for signed-out users" do
      get admin_binary_edit_access_path(@binary), xhr: true
      assert_redirected_to signin_path
    end

    test "edit_access() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_binary_edit_access_path(@binary), xhr: true
      assert_response :forbidden
    end

    test 'edit_access() returns HTTP 200' do
      sign_in_as(users(:medusa_admin))
      get admin_binary_edit_access_path(@binary), xhr: true
      assert_response :ok
    end

    # run_ocr()

    test "run_ocr() redirects to sign-in page for signed-out users" do
      patch admin_binary_run_ocr_path(@binary)
      assert_redirected_to signin_path
    end

    test "run_ocr() redirects for unauthorized users" do
      sign_in_as(users(:medusa_user))
      patch admin_binary_run_ocr_path(@binary)
      assert_redirected_to admin_collection_item_path(@binary.item.collection,
                                                      @binary.item)
    end

    test "run_ocr() redirects to the item page for binaries that do not support
    OCR" do
      sign_in_as(users(:medusa_admin))
      @binary.media_type = 'text/plain'
      patch admin_binary_run_ocr_path(@binary)
      assert_redirected_to admin_collection_item_path(@binary.item.collection,
                                                      @binary.item)
    end

    test "run_ocr() redirects to the item page for binaries that support OCR" do
      sign_in_as(users(:medusa_admin))
      patch admin_binary_run_ocr_path(@binary)
      assert_redirected_to admin_collection_item_path(@binary.item.collection,
                                                      @binary.item)
    end

    # update()

    test "update() redirects to sign-in page for signed-out users" do
      patch admin_binary_path(@binary)
      assert_redirected_to signin_path
    end

    test "update() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_binary_path(@binary)
      assert_response :forbidden
    end

    test "update() returns HTTP 200 for authorized users" do
      sign_in_as(users(:medusa_admin))
      patch admin_binary_path(@binary),
            xhr: true,
            params: {
              binary: {
                public: false
              }
            }
      assert_response :ok
    end

    test 'update() updates a binary' do
      sign_in_as(users(:medusa_admin))
      assert @binary.public

      patch admin_binary_path(@binary),
            xhr: true,
            params: {
              binary: {
                public: false
              }
            }
      @binary.reload
      assert !@binary.public
    end

  end

end