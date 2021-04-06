require 'test_helper'

class BinariesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @binary = binaries(:compound_object_1001_access)
  end

  # show()

  test 'show() returns HTTP 403 if the binary\'s item\'s collection is restricted' do
    @binary.item.collection.update!(restricted: true)
    get binary_path(@binary)
    assert_response :forbidden
  end

  test 'show() returns HTTP 403 if the binary\'s item is not authorized' do
    @binary.item.update!(allowed_netids: [{ netid: "bogus", expires: Time.now.to_i }])
    get binary_path(@binary)
    assert_response :forbidden
  end

  test 'show() returns HTTP 403 for non-public binaries' do
    @binary.update!(public: false)
    get binary_path(@binary)
    assert_response :forbidden
  end

  test 'show() returns HTTP 404 for binaries that do not exist in the repository
  bucket' do
    @binary = Binary.create!(byte_size: 100,
                             medusa_uuid: SecureRandom.uuid,
                             object_key: 'bogus')
    get binary_path(@binary)
    assert_response :not_found
  end

  test 'show() returns HTTP 200 for non-public binaries for administrators' do
    sign_in_as(users(:admin))
    @binary.update!(public: false)
    get binary_path(@binary)
    assert_response :ok
  end

  test 'show() returns JSON when requested' do
    get binary_path(@binary, format: :json)
    assert_response :ok
  end

  test 'show() returns binary data when requested' do
    get binary_path(@binary)
    assert_response :ok
  end

end
