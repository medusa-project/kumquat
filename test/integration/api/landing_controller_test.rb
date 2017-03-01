require 'test_helper'

module Api

  class LandingControllerTest < ActionDispatch::IntegrationTest

    # index()

    test 'index() should display the landing page' do
      get('/api', nil, valid_headers)
      assert_response :ok
    end

    protected

    def valid_headers
      config = Configuration.instance
      creds = ActionController::HttpAuthentication::Basic.encode_credentials(
          config.api_user, config.api_secret)
      {
          'Authorization' => creds,
          'Content-Type' => 'text/html'
      }
    end

  end

end