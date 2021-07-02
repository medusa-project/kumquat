require 'test_helper'

class BinariesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @binary = binaries(:compound_object_1001_access)
  end

  # object()

  test 'object() returns HTTP 403 if the binary\'s item\'s collection is
  restricted' do
    @binary.item.collection.update!(restricted: true)
    get binary_object_path(@binary)
    assert_response :forbidden
  end

  test 'object() returns HTTP 403 if the binary\'s item is not authorized' do
    @binary.item.update!(allowed_netids: [{ netid: "bogus", expires: Time.now.to_i }])
    get binary_object_path(@binary)
    assert_response :forbidden
  end

  test 'object() returns HTTP 403 to unauthenticated users for binaries set as
  non-public' do
    @binary.update!(public: false)
    get binary_object_path(@binary)
    assert_response :forbidden
  end

  test 'object() returns HTTP 403 for binaries whose owning collection is not
  publicizing binaries' do
    @binary.item.collection.update!(publicize_binaries: false)
    get binary_object_path(@binary)
    assert_response :forbidden
  end

  test 'object() returns HTTP 307 to authenticated users for binaries set as
  public' do
    sign_in_as(users(:admin))
    @binary.update!(public: false)
    get binary_object_path(@binary)
    assert_response :temporary_redirect
  end

  test 'object() redirects to a pre-signed URL' do
    get binary_object_path(@binary)
    assert_response :temporary_redirect
  end

  # show()

  test 'show() returns HTTP 200' do
    get binary_path(@binary)
    assert_response :ok
  end

  # stream()

  test 'stream() returns HTTP 403 if the binary\'s item\'s collection is restricted' do
    @binary.item.collection.update!(restricted: true)
    get binary_stream_path(@binary)
    assert_response :forbidden
  end

  test 'stream() returns HTTP 403 if the binary\'s item is not authorized' do
    @binary.item.update!(allowed_netids: [{ netid: "bogus", expires: Time.now.to_i }])
    get binary_stream_path(@binary)
    assert_response :forbidden
  end

  test 'stream() returns HTTP 403 to unauthenticated users for binaries set as
  non-public' do
    @binary.update!(public: false)
    get binary_stream_path(@binary)
    assert_response :forbidden
  end

  test 'stream() returns HTTP 403 for binaries whose owning collection is not
  publicizing binaries' do
    @binary.item.collection.update!(publicize_binaries: false)
    get binary_stream_path(@binary)
    assert_response :forbidden
  end

  test 'stream() returns HTTP 404 for binaries that do not exist in the
  repository bucket' do
    @binary = Binary.create!(byte_size: 100,
                             medusa_uuid: SecureRandom.uuid,
                             object_key: 'bogus')
    get binary_stream_path(@binary)
    assert_response :not_found
  end

  test 'stream() returns HTTP 200 to authenticated users for binaries set as
  public' do
    sign_in_as(users(:admin))
    @binary.update!(public: false)
    get binary_stream_path(@binary)
    assert_response :ok
  end

  test 'stream() returns binary data' do
    get binary_stream_path(@binary)
    assert_response :ok
  end

end
