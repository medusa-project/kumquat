require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest

  test 'index() returns HTTP 200' do
    user = users(:admin)
    sign_in_as(user)

    get admin_root_path
    assert_response :ok
  end

end
