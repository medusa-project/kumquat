require 'test_helper'
require File.expand_path('../abstract_harvest_controller_test.rb', __FILE__)

module Harvest

  class HarvestControllerTest < AbstractHarvestControllerTest

    setup do
      setup_elasticsearch
    end

    # index()

    test 'index() with no credentials returns HTTP 401' do
      get harvest_root_path
      assert_response :unauthorized
    end

    test 'index() with invalid credentials returns HTTP 401' do
      headers = valid_headers.merge(
        'Authorization' => ActionController::HttpAuthentication::Basic.
          encode_credentials('bogus', 'bogus'))
      get harvest_root_path, headers: headers
      assert_response :unauthorized
    end

    test 'index() with valid credentials returns HTTP 200' do
      get harvest_root_path, headers: valid_headers
      assert_response :success
    end

  end

end
