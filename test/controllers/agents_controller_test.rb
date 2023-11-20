require 'test_helper'

class AgentsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @agent = agents(:one)
  end

  # items()

  test "items() returns HTTP 406" do
    get agent_items_path(@agent)
    assert_response :not_acceptable
  end

  test "items() returns HTTP 200 via XHR" do
    get agent_items_path(@agent), xhr: true
    assert_response :ok
  end

  test "items() returns HTML" do
    get agent_items_path(@agent), xhr: true
    assert response.content_type.start_with?("text/javascript")
  end

  # show()

  test "show() returns HTTP 200" do
    get agent_path(@agent)
    assert_response :ok
  end

  test "show() returns HTML" do
    get agent_path(@agent)
    assert response.content_type.start_with?("text/html")
  end

  test "show() returns JSON" do
    get agent_path(@agent, format: :json)
    assert response.content_type.start_with?("application/json")
  end

end
