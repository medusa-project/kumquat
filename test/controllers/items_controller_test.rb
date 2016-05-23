require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @valid_xml = File.read(__dir__ + '/../fixtures/repository/image/item_1.xml')
  end

  # create()

  test 'create() with no credentials should return 401' do
    post('/items?version=1', @valid_xml)
    assert_response :unauthorized
  end

  test 'create() with invalid credentials should return 401' do
    headers = valid_headers.merge(
        'Authorization' => ActionController::HttpAuthentication::Basic.
            encode_credentials('bogus', 'bogus'))
    post('/items?version=1', @valid_xml, headers)
    assert_response :unauthorized
  end

  test 'create() with invalid content-type should return 415' do
    headers = valid_headers.merge('Content-Type' => 'text/plain')
    post('/items?version=1', @valid_xml, headers)
    assert_response :unsupported_media_type
  end

  test 'create() with missing body should return 400' do
    post('/items?version=1', nil, valid_headers)
    assert_response :bad_request
  end

  test 'create() with invalid body should return 400' do
    post('/items?version=1', '<?xml version="1.0"><bla></bla>', valid_headers)
    assert_response :bad_request
  end

  test 'create() with invalid version should return 400' do
    post('/items', @valid_xml, valid_headers)
    assert_response :bad_request
    post('/items?version=8', @valid_xml, valid_headers)
    assert_response :bad_request
  end

  test 'create() with valid credentials, content-type, and body should return 201' do
    post('/items?version=3', @valid_xml, valid_headers)
    assert_response :created
  end

  test 'create() with valid credentials and a new item should create the item' do
    assert_nil Item.find_by_repository_id('800379272_de0817d41a_tiff')
    post('/items?version=3', @valid_xml, valid_headers)
    assert_not_nil Item.find_by_repository_id('800379272_de0817d41a_tiff')
  end

  test 'create() with valid credentials and an existing item should update the item' do
    2.times do
      post('/items?version=3', @valid_xml, valid_headers)
    end
    assert_equal 1, Item.where(repository_id: '800379272_de0817d41a_tiff').count
  end

  # delete()

  test 'delete() with no credentials should return 401' do
    delete('/items/item1', nil, {})
    assert_response :unauthorized
  end

  test 'delete() with invalid credentials should return 401' do
    headers = valid_headers.merge(
        'Authorization' => ActionController::HttpAuthentication::Basic.
            encode_credentials('bogus', 'bogus'))
    delete('/items/item1', nil, headers)
    assert_response :unauthorized
  end

  test 'delete() with invalid resource should return 404' do
    delete('/items/bogus', nil, valid_headers)
    assert_response :not_found
  end

  test 'delete() should return 200' do
    delete('/items/item1', nil, valid_headers)
    assert_response :success
  end

  test 'delete() should delete the item' do
    delete('/items/item1', nil, valid_headers)
    assert_equal 0, Item.where(repository_id: 'item1').count
  end

  # show() with JSON

  test 'show() JSON should return 200' do
    get('/items/item1.json')
    assert_response :success
  end

  # show() with XML

  test 'show() XML with no credentials should return 401' do
    get('/items/item1.xml?version=1')
    assert_response :unauthorized
  end

  test 'show() XML with invalid credentials should return 401' do
    headers = valid_headers.merge(
        'Authorization' => ActionController::HttpAuthentication::Basic.
            encode_credentials('bogus', 'bogus'))
    get('/items/item1.xml?version=1', nil, headers)
    assert_response :unauthorized
  end

  test 'show() with no version should return 200' do
    get('/items/item1.xml', nil, valid_headers)
    assert_response :success
  end

  test 'show() with invalid version should return 400' do
    get('/items/item1.xml?version=9', nil, valid_headers)
    assert_response :bad_request
  end

  test 'show() with valid credentials should return 200' do
    get('/items/item1.xml?version=3', nil, valid_headers)
    assert_response :success
  end

  private

  def valid_headers
    config = PearTree::Application.peartree_config
    creds = ActionController::HttpAuthentication::Basic.encode_credentials(
        config[:api_user], config[:api_secret])
    {
        'Authorization' => creds,
        'Content-Type' => 'application/xml'
    }
  end

end

