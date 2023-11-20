require 'test_helper'

class AgentRulePolicyTest < ActiveSupport::TestCase

  # create?()

  test "create?() authorizes Medusa super admins" do
    assert AgentRulePolicy.new(users(:medusa_super_admin), AgentRule).create?
  end

  test "create?() authorizes Medusa admins" do
    assert AgentRulePolicy.new(users(:medusa_admin), AgentRule).create?
  end

  test "create?() does not authorize Medusa users" do
    assert !AgentRulePolicy.new(users(:medusa_user), AgentRule).create?
  end

  test "create?() does not authorize normal users" do
    assert !AgentRulePolicy.new(users(:normal), AgentRule).create?
  end

  # destroy?()

  test "destroy?() authorizes Medusa super admins" do
    assert AgentRulePolicy.new(users(:medusa_super_admin),
                               agent_rules(:one)).destroy?
  end

  test "destroy?() authorizes Medusa admins" do
    assert AgentRulePolicy.new(users(:medusa_admin),
                               agent_rules(:one)).destroy?
  end

  test "destroy?() does not authorize Medusa users" do
    assert !AgentRulePolicy.new(users(:medusa_user),
                                agent_rules(:one)).destroy?
  end

  test "destroy?() does not authorize normal users" do
    assert !AgentRulePolicy.new(users(:normal),
                                agent_rules(:one)).destroy?
  end

  # edit?()

  test "edit?() authorizes Medusa super admins" do
    assert AgentRulePolicy.new(users(:medusa_super_admin),
                               agent_rules(:one)).edit?
  end

  test "edit?() authorizes Medusa admins" do
    assert AgentRulePolicy.new(users(:medusa_admin),
                               agent_rules(:one)).edit?
  end

  test "edit?() does not authorize Medusa users" do
    assert !AgentRulePolicy.new(users(:medusa_user),
                                agent_rules(:one)).edit?
  end

  test "edit?() does not authorize normal users" do
    assert !AgentRulePolicy.new(users(:normal),
                                agent_rules(:one)).edit?
  end

  # index?()

  test "index?() authorizes Medusa super admins" do
    assert AgentRulePolicy.new(users(:medusa_super_admin), AgentRule).index?
  end

  test "index?() authorizes Medusa admins" do
    assert AgentRulePolicy.new(users(:medusa_admin), AgentRule).index?
  end

  test "index?() does not authorize Medusa users" do
    assert !AgentRulePolicy.new(users(:medusa_user), AgentRule).index?
  end

  test "index?() does not authorize normal users" do
    assert !AgentRulePolicy.new(users(:normal), AgentRule).index?
  end

  # new?()

  test "new?() authorizes Medusa super admins" do
    assert AgentRulePolicy.new(users(:medusa_super_admin), AgentRule).new?
  end

  test "new?() authorizes Medusa admins" do
    assert AgentRulePolicy.new(users(:medusa_admin), AgentRule).new?
  end

  test "new?() does not authorize Medusa users" do
    assert !AgentRulePolicy.new(users(:medusa_user), AgentRule).new?
  end

  test "new?() does not authorize normal users" do
    assert !AgentRulePolicy.new(users(:normal), AgentRule).new?
  end

  # update?()

  test "update?() authorizes Medusa super admins" do
    assert AgentRulePolicy.new(users(:medusa_super_admin),
                               agent_rules(:one)).update?
  end

  test "update?() authorizes Medusa admins" do
    assert AgentRulePolicy.new(users(:medusa_admin),
                               agent_rules(:one)).update?
  end

  test "update?() does not authorize Medusa users" do
    assert !AgentRulePolicy.new(users(:medusa_user),
                                agent_rules(:one)).update?
  end

  test "update?() does not authorize normal users" do
    assert !AgentRulePolicy.new(users(:normal),
                                agent_rules(:one)).update?
  end

end
