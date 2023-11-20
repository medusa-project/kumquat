require 'test_helper'

module Harvest

  class AbstractHarvestControllerTest < ActionDispatch::IntegrationTest

    protected

    def valid_headers
      user = users(:medusa_admin)
      creds = ActionController::HttpAuthentication::Basic.encode_credentials(
        user.username, user.api_key)
      {
        'Authorization' => creds,
        'Content-Type' => 'application/json'
      }
    end

  end

end