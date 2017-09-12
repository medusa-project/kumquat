require 'test_helper'

module Api

  class CollectionsControllerTest < ActionDispatch::IntegrationTest

    # index()

    test 'index() with no credentials should return 401' do
      get('/api/collections')
      assert_response :unauthorized
    end

    test 'index() with invalid credentials should return 401' do
      headers = valid_headers.merge(
          'Authorization' => ActionController::HttpAuthentication::Basic.
              encode_credentials('bogus', 'bogus'))
      get '/api/collections', headers: headers
      assert_response :unauthorized
    end

    test 'index() with valid credentials should return 200' do
      Collection.all.each { |c| c.reindex }
      sleep 2

      get '/api/collections', headers: valid_headers
      assert_response :success
    end

    protected

    def valid_headers
      config = Configuration.instance
      creds = ActionController::HttpAuthentication::Basic.encode_credentials(
          config.api_user, config.api_secret)
      {
          'Authorization' => creds,
          'Content-Type' => 'application/json'
      }
    end

  end

end