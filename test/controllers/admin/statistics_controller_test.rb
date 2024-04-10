require 'test_helper'

module Admin

  class StatisticsControllerTest < ActionDispatch::IntegrationTest

    setup do
      setup_opensearch
    end

    # index()

    test "index() redirects to sign-in page for signed-out users" do
      get admin_statistics_path
      assert_redirected_to signin_path
    end

    test "index() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_statistics_path
      assert_response :forbidden
    end

    test "index() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      get admin_statistics_path
      assert_response :ok
    end

  end

end
