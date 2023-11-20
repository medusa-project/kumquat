require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest

  setup do
    sign_out
  end

  test "index() redirects for logged-out users" do
    get admin_root_path
    assert_redirected_to signin_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    user = users(:normal)
    sign_in_as(user)

    get admin_root_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    user = users(:medusa_user)
    sign_in_as(user)

    get admin_root_path
    assert_response :ok
  end

end
