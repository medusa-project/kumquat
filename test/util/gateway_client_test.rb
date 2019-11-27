require 'test_helper'

class GatewayClientTest < ActiveSupport::TestCase

  test 'num_items works' do
    assert GatewayClient.instance.num_items > 1000000
  end

end
