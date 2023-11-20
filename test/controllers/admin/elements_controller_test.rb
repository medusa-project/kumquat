require 'test_helper'

class ElementsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @element = elements(:title)
    sign_out
  end

  # create()

  test "create() redirects to sign-in page for signed-out users" do
    post admin_elements_path
    assert_redirected_to signin_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    post admin_elements_path,
         xhr: true,
         params: {
           element: {
             name: "test"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_admin))
    post admin_elements_path, xhr: true,
         params: {
           element: {
             name: "test"
           }
         }
    assert_response :ok
  end

  # destroy()

  test "destroy() redirects to sign-in page for signed-out users" do
    delete admin_element_path(@element)
    assert_redirected_to signin_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    delete admin_element_path(@element)
    assert_response :forbidden
  end

  test "destroy() redirects for authorized users" do
    sign_in_as(users(:medusa_admin))
    delete admin_element_path(@element)
    assert_redirected_to admin_elements_path
  end

  # edit()

  test "edit() redirects to sign-in page for signed-out users" do
    get edit_admin_element_path(@element), xhr: true
    assert_redirected_to signin_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get edit_admin_element_path(@element), xhr: true
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_admin))
    get edit_admin_element_path(@element), xhr: true
    assert_response :ok
  end

  # import()

  test "import() redirects to sign-in page for signed-out users" do
    post admin_elements_import_path(@element), xhr: true
    assert_redirected_to signin_path
  end

  test "import() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    post admin_elements_import_path(@element), xhr: true
    assert_response :forbidden
  end

  test "import() redirects for authorized users" do
    sign_in_as(users(:medusa_admin))
    post admin_elements_import_path(@element), xhr: true
    assert_redirected_to admin_elements_path
  end

  # index()

  test "index() redirects to sign-in page for signed-out users" do
    get admin_elements_path
    assert_redirected_to signin_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get admin_elements_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_user))
    get admin_elements_path
    assert_response :ok
  end

  test "index() returns HTML" do
    sign_in_as(users(:medusa_user))
    get admin_elements_path
    assert response.content_type.start_with?("text/html")
  end

  test "index() returns JSON" do
    sign_in_as(users(:medusa_user))
    get admin_elements_path(format: :json)
    assert response.content_type.start_with?("application/json")
  end

  # show()

  test "show() redirects to sign-in page for signed-out users" do
    get admin_element_path(@element)
    assert_redirected_to signin_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get admin_element_path(@element)
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_user))
    get admin_element_path(@element)
    assert_response :ok
  end

  # update()

  test "update() redirects to sign-in page for signed-out users" do
    patch admin_element_path(@element)
    assert_redirected_to signin_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    patch admin_element_path(@element)
    assert_response :forbidden
  end

  test "update() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_admin))
    patch admin_element_path(@element),
          xhr: true,
          params: {
            element: {
              label: "New Label"
            }
          }
    assert_response :ok
  end

  # usages()

  test "usages() redirects to sign-in page for signed-out users" do
    get admin_element_usages_path(@element)
    assert_redirected_to signin_path
  end

  test "usages() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get admin_element_usages_path(@element)
    assert_response :forbidden
  end

  test "usages() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_user))
    get admin_element_usages_path(@element)
    assert_response :ok
  end

end
