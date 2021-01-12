require 'test_helper'
require File.expand_path('../abstract_harvest_controller_test.rb', __FILE__)

module Harvest

  class ItemsControllerTest < AbstractHarvestControllerTest

    def setup
      @item = items(:free_form_dir1_dir1_file1)
    end

    # show()

    test 'show() with no credentials returns HTTP 401' do
      get harvest_item_path(@item)
      assert_response :unauthorized
    end

    test 'show() with invalid credentials returns HTTP 401' do
      headers = valid_headers.merge(
        'Authorization' => ActionController::HttpAuthentication::Basic.
          encode_credentials('bogus', 'bogus'))
      get harvest_item_path(@item), headers: headers
      assert_response :unauthorized
    end

    test 'show() with valid credentials returns HTTP 200' do
      get harvest_item_path(@item), headers: valid_headers
      assert_response :success
    end

  end

end
