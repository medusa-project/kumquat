require 'test_helper'

class LandingControllerTest < ActionDispatch::IntegrationTest

  # index()

  test "index() renders the landing page" do
    get root_path
    assert_response :ok
  end

  test "index() does not return an X-Frame-Options header" do
    get root_path
    assert response.header['X-Frame-Options'].blank?
  end

end

