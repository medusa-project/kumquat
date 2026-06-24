require 'test_helper'
require 'mocha/minitest'

class GatewayClientTest < ActiveSupport::TestCase

  test 'num_items works' do
    fake_response = stub(body: '{"numResults":2000000}')
    HTTPClient.any_instance.stubs(:get).returns(fake_response)
    assert GatewayClient.instance.num_items > 1_000_000
  end

end
