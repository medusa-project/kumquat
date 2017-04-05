require 'test_helper'

class FavoritesControllerTest < ActionDispatch::IntegrationTest

  test 'index() should return HTTP 200' do
    get('/favorites')
    assert_response :ok
  end

end

