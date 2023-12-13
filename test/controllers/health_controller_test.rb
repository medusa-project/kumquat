require 'test_helper'

class HealthControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_opensearch
  end

  # index()

  test 'index() returns HTTP 200 when the health check passes' do
    get health_path
    assert_response :ok
  end

  test 'index() returns HTTP 500 when the database is not responding' do
    skip # TODO: write this somehow
    get health_path
    assert_response :internal_server_error
  end

  test 'index() returns HTTP 500 when OpenSearch is not responding' do
    skip # TODO: write this somehow
    get health_path
    assert_response :internal_server_error
  end

end
