require 'test_helper'

module Admin

  class UsersControllerTest < ActionDispatch::IntegrationTest

    setup do
      @user = users(:normal)
      sign_out
    end

    # create()

    test "create() redirects to sign-in page for signed-out users" do
      post admin_users_path
      assert_redirected_to signin_path
    end

    test "create() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_users_path,
           params: {
             user: {
               username: "newuser",
               human:    false
             }
           }
      assert_response :forbidden
    end

    test "create() redirects upon success" do
      sign_in_as(users(:medusa_super_admin))
      post admin_users_path,
           params: {
             user: {
               username: "newuser",
               human:    false
             }
           }
      assert_redirected_to admin_users_path
    end

    # destroy()

    test "destroy() redirects to sign-in page for signed-out users" do
      delete admin_user_path(@user)
      assert_redirected_to signin_path
    end

    test "destroy() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      delete admin_user_path(@user)
      assert_response :forbidden
    end

    test "destroy() redirects upon success" do
      sign_in_as(users(:medusa_super_admin))
      delete admin_user_path(@user)
      assert_redirected_to admin_users_path
    end

    test "destroy() destroys the instance" do
      sign_in_as(users(:medusa_super_admin))
      delete admin_user_path(@user)
      assert_raises ActiveRecord::RecordNotFound do
        @user.reload
      end
    end

    # index()

    test "index() redirects to sign-in page for signed-out users" do
      get admin_users_path
      assert_redirected_to signin_path
    end

    test "index() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_users_path
      assert_response :forbidden
    end

    test "index() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      get admin_users_path
      assert_response :ok
    end

    # new()

    test "new() redirects to sign-in page for signed-out users" do
      get new_admin_user_path
      assert_redirected_to signin_path
    end

    test "new() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get new_admin_user_path
      assert_response :forbidden
    end

    test "new() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      get new_admin_user_path
      assert_response :ok
    end

    # reset_api_key()

    test "reset_api_key() redirects to sign-in page for signed-out users" do
      post admin_user_reset_api_key_path(@user)
      assert_redirected_to signin_path
    end

    test "reset_api_key() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_user_reset_api_key_path(@user)
      assert_response :forbidden
    end

    test "reset_api_key() redirects upon success" do
      sign_in_as(users(:medusa_super_admin))
      post admin_user_reset_api_key_path(@user)
      assert_redirected_to admin_user_path(@user)
    end

    test "reset_api_key() resets the user's API key" do
      initial_key = @user.api_key
      sign_in_as(users(:medusa_super_admin))
      post admin_user_reset_api_key_path(@user)

      @user.reload
      assert_not_equal initial_key, @user.api_key
    end

    # show()

    test "show() redirects to sign-in page for signed-out users" do
      get admin_user_path(@user)
      assert_redirected_to signin_path
    end

    test "show() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_user_path(@user)
      assert_response :forbidden
    end

    test "show() returns HTTP 200" do
      sign_in_as(users(:medusa_super_admin))
      get admin_user_path(@user)
      assert_response :ok
    end

  end

end
