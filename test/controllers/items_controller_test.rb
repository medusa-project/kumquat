require 'test_helper'

class ItemsControllerTest < ActionController::TestCase

  def setup
    @valid_xml = File.read(__dir__ + '/../fixtures/repository/image/item_1.xml')
  end

  # create()

  test 'create() with no credentials should return 401' do
    post :create
    assert_response :unauthorized
  end

  test 'create() with invalid credentials should return 401' do
    send_invalid_credentials
    post :create
    assert_response :unauthorized
  end

  test 'create() with valid credentials but invalid content-type should return 415' do
    send_valid_credentials
    request.env['CONTENT_TYPE'] = 'text/plain'
    post :create
    assert_response :unsupported_media_type
  end

  test 'create() with valid credentials and content-type but missing body should return 400' do
    send_valid_credentials
    request.env['CONTENT_TYPE'] = 'application/xml'
    post :create
    assert_response :bad_request
  end

  test 'create() with valid credentials and content-type but invalid body should return 400' do
    send_valid_credentials
    request.env['CONTENT_TYPE'] = 'application/xml'
    post :create, '<?xml version="1.0"><bla></bla>'
    assert_response :bad_request
  end

  test 'create() with valid credentials, content-type, and body should return 201' do
    send_valid_credentials
    request.env['CONTENT_TYPE'] = 'application/xml'
    post :create, @valid_xml
    assert_response :created
  end

  test 'create() with valid credentials and a new item should create the item' do
    assert_nil Item.find_by_repository_id('800379272_de0817d41a_tiff')

    send_valid_credentials
    request.env['CONTENT_TYPE'] = 'application/xml'
    post :create, @valid_xml

    assert_not_nil Item.find_by_repository_id('800379272_de0817d41a_tiff')
  end

  test 'create() with valid credentials and an existing item should update the item' do
    2.times do
      send_valid_credentials
      request.env['CONTENT_TYPE'] = 'application/xml'
      post :create, @valid_xml
    end
    assert_equal 1, Item.where(repository_id: '800379272_de0817d41a_tiff').count
  end

  private

  def send_credentials(username, secret)
    request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(username, secret)
  end

  def send_invalid_credentials
    send_credentials('bogus', 'bogus')
  end

  def send_valid_credentials
    config = PearTree::Application.peartree_config
    send_credentials(config[:api_user], config[:api_secret])
  end

end

