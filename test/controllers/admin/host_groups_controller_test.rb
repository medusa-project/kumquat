require 'test_helper'

class HostGroupsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @host_group = host_groups(:blue)
    sign_out
  end

  # create()

  test "create() redirects to sign-in page for signed-out users" do
    post admin_host_groups_path
    assert_redirected_to signin_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    post admin_host_groups_path,
         xhr: true,
         params: {
           host_group: {
             name: "New Name"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_admin))
    post admin_host_groups_path, xhr: true,
         params: {
           host_group: {
             name: "test"
           }
         }
    assert_response :ok
  end

  # destroy()

  test "destroy() redirects to sign-in page for signed-out users" do
    delete admin_host_group_path(@host_group)
    assert_redirected_to signin_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    delete admin_host_group_path(@host_group)
    assert_response :forbidden
  end

  test "destroy() redirects for authorized users" do
    sign_in_as(users(:medusa_admin))
    delete admin_host_group_path(@host_group)
    assert_redirected_to admin_host_groups_path
  end

  # edit()

  test "edit() redirects to sign-in page for signed-out users" do
    get edit_admin_host_group_path(@host_group), xhr: true
    assert_redirected_to signin_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get edit_admin_host_group_path(@host_group), xhr: true
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_admin))
    get edit_admin_host_group_path(@host_group), xhr: true
    assert_response :ok
  end

  # index()

  test "index() redirects to sign-in page for signed-out users" do
    get admin_host_groups_path
    assert_redirected_to signin_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get admin_host_groups_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_admin))
    get admin_host_groups_path
    assert_response :ok
  end

  # new()

  test "new() redirects to sign-in page for signed-out users" do
    get new_admin_host_group_path
    assert_redirected_to signin_path
  end

  test "new() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get new_admin_host_group_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_admin))
    get new_admin_host_group_path
    assert_response :ok
  end

  # show()

  test "show() redirects to sign-in page for signed-out users" do
    get admin_host_group_path(@host_group)
    assert_redirected_to signin_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get admin_host_group_path(@host_group)
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    sign_in_as(users(:medusa_admin))
    get admin_host_group_path(@host_group)
    assert_response :ok
  end

  # update()

  test "update() redirects to sign-in page for signed-out users" do
    patch admin_host_group_path(@host_group)
    assert_redirected_to signin_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    patch admin_host_group_path(@host_group)
    assert_response :forbidden
  end

  test "update() redirects for authorized users" do
    sign_in_as(users(:medusa_admin))
    patch admin_host_group_path(@host_group),
          xhr: true,
          params: {
            host_group: {
              name: "New Name"
            }
          }
    assert_redirected_to admin_host_groups_path
  end

end
