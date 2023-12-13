require 'test_helper'

class AgentPolicyTest < ActiveSupport::TestCase

  setup do
    @agent   = agents(:one)
    @context = RequestContext.new(client_ip:       "127.0.0.1",
                                  client_hostname: "example.org")
  end

  # items?()

  test "items?() authorizes everyone" do
    assert AgentPolicy.new(@context, @agent).items?
  end

  # show?()

  test "show?() authorizes everyone" do
    assert AgentPolicy.new(@context, @agent).show?
  end

end
