require 'test_helper'

module Admin

  class SettingsControllerTest < ActionDispatch::IntegrationTest

    # index()

    test "index() redirects to sign-in page for signed-out users" do
      get admin_settings_path
      assert_redirected_to signin_path
    end

    test "index() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_settings_path
      assert_response :forbidden
    end

    test "index() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      get admin_settings_path
      assert_response :ok
    end

    # update()

    test "update() redirects to sign-in page for signed-out users" do
      patch admin_settings_path
      assert_redirected_to signin_path
    end

    test "update() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_settings_path
      assert_response :forbidden
    end

    test "update() redirects upon success" do
      sign_in_as(users(:medusa_admin))
      patch admin_settings_path,
            params: {
              options: {
                cats: "dogs"
              }
            }
      assert_redirected_to admin_settings_path
    end

    test "update() updates settings" do
      sign_in_as(users(:medusa_admin))
      patch admin_settings_path,
            params: {
              options: {
                cats: "dogs"
              }
            }
      assert_equal "dogs", Setting.string("cats")
      assert_redirected_to admin_settings_path
    end

  end

end
