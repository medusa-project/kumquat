require 'test_helper'

class BinariesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @binary = binaries(:compound_object_1001_access)
  end

  # edit()

  test "edit() redirects to sign-in page for signed-out users" do
    get edit_admin_binary_path(@binary)
    assert_redirected_to signin_path
  end

  test 'edit() returns HTTP 200' do
    sign_in_as(users(:admin))
    get edit_admin_binary_path(@binary), {
        xhr: true,
        params: {
            binary: {
                public: true
            }
        }
    }
    assert_response :ok
  end

  # update()

  test "update() redirects to sign-in page for signed-out users" do
    patch admin_binary_path(@binary)
    assert_redirected_to signin_path
  end

  test 'update() updates a binary' do
    sign_in_as(users(:admin))
    assert @binary.public

    patch admin_binary_path(@binary), {
        xhr: true,
        params: {
            binary: {
                public: false
            }
        }
    }
    @binary.reload
    assert !@binary.public
  end

end

