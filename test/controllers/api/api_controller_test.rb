require 'test_helper'

module Api

  class ApiControllerTest < ActionDispatch::IntegrationTest

    protected

    def valid_headers
      user = users(:admin)
      creds = ActionController::HttpAuthentication::Basic.encode_credentials(
          user.username, user.api_key)
      {
          'Authorization' => creds,
          'Content-Type' => 'application/json'
      }
    end

  end

end