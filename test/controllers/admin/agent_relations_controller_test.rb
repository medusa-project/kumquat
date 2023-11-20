require 'test_helper'

class AgentRelationsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @relation = agent_relations(:one)
  end

  # create()

  test "create() redirects to sign-in page for signed-out users" do
    post admin_agent_relations_path
    assert_redirected_to signin_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    post admin_agent_relations_path,
         xhr: true,
         params: {
           agent_relation: {
             name:        "Test",
             description: "Test",
             uri:         "http://example.org/test"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    post admin_agent_relations_path,
         xhr: true,
         params: {
           agent_relation: {
             name:        "Test",
             description: "Test",
             uri:         "http://example.org/test"
           }
         }
    assert_response :ok
  end

  # destroy()

  test "destroy() redirects to sign-in page for signed-out users" do
    delete admin_agent_relation_path(@relation)
    assert_redirected_to signin_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    delete admin_agent_relation_path(@relation)
    assert_response :forbidden
  end

  test "destroy() redirects upon success" do
    sign_in_as(users(:medusa_admin))
    delete admin_agent_relation_path(@relation)
    assert_redirected_to admin_agent_relations_path
  end

  test "destroy() destroys the instance" do
    Agent.delete_all # avoid foreign key constraints
    sign_in_as(users(:medusa_admin))
    delete admin_agent_relation_path(@relation)
    assert_raises ActiveRecord::RecordNotFound do
      @relation.reload
    end
  end

  # edit()

  test "edit() redirects to sign-in page for signed-out users" do
    get edit_admin_agent_relation_path(@relation), xhr: true
    assert_redirected_to signin_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get edit_admin_agent_relation_path(@relation), xhr: true
    assert_response :forbidden
  end

  test "edit() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    get edit_admin_agent_relation_path(@relation), xhr: true
    assert_response :ok
  end

  # update()

  test "update() redirects to sign-in page for signed-out users" do
    patch admin_agent_relation_path(@relation)
    assert_redirected_to signin_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    patch admin_agent_relation_path(@relation),
          xhr: true,
          params: {
            agent_relation: {
              name:        "Test",
              description: "Test",
              uri:         "http://example.org/test"
            }
          }
    assert_response :forbidden
  end

  test "update() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    patch admin_agent_relation_path(@relation),
          xhr: true,
          params: {
            agent_relation: {
              name:        "Test",
              description: "Test",
              uri:         "http://example.org/test"
            }
          }
    assert_response :ok
  end

end

