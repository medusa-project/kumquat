require 'test_helper'

module Admin

  class TasksControllerTest < ActionDispatch::IntegrationTest

    setup do
      @task = tasks(:waiting)
    end

    # index()

    test "index() redirects to sign-in page for signed-out users" do
      get admin_tasks_path
      assert_redirected_to signin_path
    end

    test "index() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_tasks_path
      assert_response :forbidden
    end

    test "index() returns HTTP 200" do
      sign_in_as(users(:medusa_user))
      get admin_tasks_path
      assert_response :ok
    end

    # show()

    test "show() redirects to sign-in page for signed-out users" do
      get admin_task_path(@task)
      assert_redirected_to signin_path
    end

    test "show() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_task_path(@task)
      assert_response :forbidden
    end

    test "show() returns HTTP 200" do
      sign_in_as(users(:medusa_user))
      get admin_task_path(@task)
      assert_response :ok
    end

  end

end
