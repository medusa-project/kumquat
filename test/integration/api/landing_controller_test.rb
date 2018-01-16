require 'test_helper'
require File.expand_path('../api_controller_test.rb', __FILE__)

module Api

  class LandingControllerTest < ApiControllerTest

    # index()

    test 'index() should display the landing page' do
      get '/api', headers: valid_headers
      assert_response :ok
    end

  end

end