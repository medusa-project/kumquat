require 'test_helper'
require File.expand_path('../abstract_harvest_controller_test.rb', __FILE__)

module Harvest

  class CollectionsControllerTest < AbstractHarvestControllerTest

    setup do
      @collection = collections(:compound_object)
    end

    # show()

    test 'show() with no credentials returns HTTP 401' do
      get harvest_collection_path(@collection)
      assert_response :unauthorized
    end

    test 'show() with invalid credentials returns HTTP 401' do
      headers = valid_headers.merge(
        'Authorization' => ActionController::HttpAuthentication::Basic.
          encode_credentials('bogus', 'bogus'))
      get harvest_collection_path(@collection), headers: headers
      assert_response :unauthorized
    end

    test 'show() with valid credentials returns HTTP 200' do
      get harvest_collection_path(@collection), headers: valid_headers
      assert_response :success
    end

  end

end
