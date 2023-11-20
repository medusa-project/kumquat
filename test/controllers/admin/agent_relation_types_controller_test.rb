require 'test_helper'

class AgentRelationTypesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @type = agent_relation_types(:one)
  end

  # create()

  test "create() redirects to sign-in page for signed-out users" do
    post admin_agent_relation_types_path
    assert_redirected_to signin_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    post admin_agent_relation_types_path,
         xhr: true,
         params: {
           agent_relation_type: {
             name:        "Test",
             description: "Test",
             uri:         "http://example.org/test"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    post admin_agent_relation_types_path,
         xhr: true,
         params: {
           agent_relation_type: {
             name:        "Test",
             description: "Test",
             uri:         "http://example.org/test"
           }
         }
    assert_response :ok
  end

  # destroy()

  test "destroy() redirects to sign-in page for signed-out users" do
    delete admin_agent_relation_type_path(@type)
    assert_redirected_to signin_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    delete admin_agent_relation_type_path(@type)
    assert_response :forbidden
  end

  test "destroy() redirects upon success" do
    sign_in_as(users(:medusa_admin))
    delete admin_agent_relation_type_path(@type)
    assert_redirected_to admin_agent_relation_types_path
  end

  test "destroy() destroys the instance" do
    Agent.delete_all # avoid foreign key constraints
    sign_in_as(users(:medusa_admin))
    delete admin_agent_relation_type_path(@type)
    assert_raises ActiveRecord::RecordNotFound do
      @type.reload
    end
  end

  # edit()

  test "edit() redirects to sign-in page for signed-out users" do
    get edit_admin_agent_relation_type_path(@type), xhr: true
    assert_redirected_to signin_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get edit_admin_agent_relation_type_path(@type), xhr: true
    assert_response :forbidden
  end

  test "edit() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    get edit_admin_agent_relation_type_path(@type), xhr: true
    assert_response :ok
  end

  # index()

  test "index() redirects to sign-in page for signed-out users" do
    get admin_agent_relation_types_path
    assert_redirected_to signin_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get admin_agent_relation_types_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    get admin_agent_relation_types_path
    assert_response :ok
  end

  # update()

  test "update() redirects to sign-in page for signed-out users" do
    patch admin_agent_relation_type_path(@type)
    assert_redirected_to signin_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    patch admin_agent_relation_type_path(@type),
         xhr: true,
         params: {
           agent_relation_type: {
             name:        "Test",
             description: "Test",
             uri:         "http://example.org/test"
           }
         }
    assert_response :forbidden
  end

  test "update() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    patch admin_agent_relation_type_path(@type),
         xhr: true,
         params: {
           agent_relation_type: {
             name:        "Test",
             description: "Test",
             uri:         "http://example.org/test"
           }
         }
    assert_response :ok
  end

end

