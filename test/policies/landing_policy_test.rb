require 'test_helper'

class LandingPolicyTest < ActiveSupport::TestCase

  setup do
    @context = RequestContext.new(client_ip:       "127.0.0.1",
                                  client_hostname: "example.org")
  end

  # index?()

  test "index?() authorizes everyone" do
    assert LandingPolicy.new(@context, nil).index?
  end

end
