require 'test_helper'
require 'mocha/minitest'

class ApplicationControllerTest < ActionDispatch::IntegrationTest

  def setup
    @item = items(:compound_object_1001)
    setup_opensearch
  end

  # rescue_internal_server_error()

  test 'rescue_internal_server_error does not email admins for known bot User-Agents' do 

    # Stub ItemsController#index action to raise an exception

    ItemsController.any_instance.stubs(:index).raises(StandardError, 'test error')

    # Simulate a GET request to items_path with a user agent with a bot User-Agent header (e.g., Googlebot)
    # Assert NO email is sent to admin
    
    assert_no_emails do 
      get items_path, headers: { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' }
    end
    assert_response :internal_server_error
  end

  test 'rescue_internal_server_error emails admins for non-bot User-Agents' do 

    # Stub ItemsController#index action to raise an exception

    ItemsController.any_instance.stubs(:index).raises(StandardError, 'test error')

    # Simulate a GET request to items_path with a user agent with a non-bot User-Agent header (e.g., Mozilla/5.0)
    # Assert 1 email is sent/delivered to admin

    assert_emails 1 do 
      get items_path, headers: { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36' }
    end
    assert_response :internal_server_error
  end
end