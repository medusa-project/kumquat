require 'test_helper'
require File.expand_path('../api_controller_test.rb', __FILE__)

module Api

  class ItemsControllerTest < ApiControllerTest

    setup do
      @item = items(:illini_union_dir1_dir1_file1)
      @item.reindex
      sleep 2
    end

    # delete()

    test 'delete() with no credentials should return 401' do
      delete '/api/items/' + @item.repository_id, headers: {}
      assert_response :unauthorized
    end

    test 'delete() with invalid credentials should return 401' do
      headers = valid_headers.merge(
          'Authorization' => ActionController::HttpAuthentication::Basic.
              encode_credentials('bogus', 'bogus'))
      delete '/api/items/' + @item.repository_id, headers: headers
      assert_response :unauthorized
    end

    test 'delete() with invalid resource should return 404' do
      delete '/api/items/bogus', headers: valid_headers
      assert_response :not_found
    end

    test 'delete() should return 200' do
      delete '/api/items/' + @item.repository_id, headers: valid_headers
      assert_response :success
    end

    test 'delete() should delete the item' do
      id = @item.repository_id
      delete '/api/items/' + id, headers: valid_headers
      assert_nil Item.find_by_repository_id(id)
    end

    # index()

    test 'index() with no credentials should return 401' do
      get '/api/items.json'
      assert_response :unauthorized
    end

    test 'index() with invalid credentials should return 401' do
      headers = valid_headers.merge(
          'Authorization' => ActionController::HttpAuthentication::Basic.
              encode_credentials('bogus', 'bogus'))
      get '/api/items.json', headers: headers
      assert_response :unauthorized
    end

    test 'index() with valid credentials should return 200' do
      get '/api/items.json', headers: valid_headers
      assert_response :success
    end

    # show()

    test 'show() with no credentials should return 401' do
      get '/api/items/' + @item.repository_id + '.json'
      assert_response :unauthorized
    end

    test 'show() with invalid credentials should return 401' do
      headers = valid_headers.merge(
          'Authorization' => ActionController::HttpAuthentication::Basic.
              encode_credentials('bogus', 'bogus'))
      get '/api/items/' + @item.repository_id + '.json', headers: headers
      assert_response :unauthorized
    end

    test 'show() with valid credentials should return 200' do
      get '/api/items/' + @item.repository_id + '.json', headers: valid_headers
      assert_response :success
    end

    # update()

    test 'update() with no credentials should return 401' do
      put '/api/items/' + @item.repository_id, headers: {}
      assert_response :unauthorized
    end

    test 'update() with invalid credentials should return 401' do
      headers = valid_headers.merge(
          'Authorization' => ActionController::HttpAuthentication::Basic.
              encode_credentials('bogus', 'bogus'))
      put '/api/items/' + @item.repository_id, headers: headers
      assert_response :unauthorized
    end

    test 'update() with invalid resource should return 404' do
      put '/api/items/bogus', headers: valid_headers
      assert_response :not_found
    end

    test 'update() with invalid content type should return 405' do
      json = @item.to_json
      headers = valid_headers.merge('Content-Type' => 'unknown/unknown')
      put '/api/items/' + @item.repository_id, params: json, headers: headers
      assert_response :unsupported_media_type
    end

    test 'update() should return 200' do
      json = @item.to_json
      put '/api/items/' + @item.repository_id, params: json,
          headers: valid_headers
      assert_response :success
    end

    test 'update() should update the item' do
      initial_json = @item.to_json
      body = @item.as_json
      body['page_number'] = 99
      json = JSON.generate(body)
      put '/api/items/' + @item.repository_id, params: json,
          headers: valid_headers

      # Compare the current JSON representation to the first one.
      initial_struct = JSON.parse(initial_json)
      @item.reload
      current_struct = @item.as_json

      assert_equal 99, current_struct['page_number']
      assert_not_equal initial_struct['updated_at'],
                       current_struct['updated_at']
      assert_equal initial_struct['elements'].length,
                   current_struct['elements'].length
    end

  end

end