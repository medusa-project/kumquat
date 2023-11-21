require 'test_helper'

module Admin

  class AgentTypePolicyTest < ActiveSupport::TestCase

    # create?()

    test "create?() authorizes Medusa super admins" do
      assert AgentTypePolicy.new(users(:medusa_super_admin), AgentType).create?
    end

    test "create?() authorizes Medusa admins" do
      assert AgentTypePolicy.new(users(:medusa_admin), AgentType).create?
    end

    test "create?() does not authorize Medusa users" do
      assert !AgentTypePolicy.new(users(:medusa_user), AgentType).create?
    end

    test "create?() does not authorize normal users" do
      assert !AgentTypePolicy.new(users(:normal), AgentType).create?
    end

    # destroy?()

    test "destroy?() authorizes Medusa super admins" do
      assert AgentTypePolicy.new(users(:medusa_super_admin),
                                 agent_types(:one)).destroy?
    end

    test "destroy?() authorizes Medusa admins" do
      assert AgentTypePolicy.new(users(:medusa_admin),
                                 agent_types(:one)).destroy?
    end

    test "destroy?() does not authorize Medusa users" do
      assert !AgentTypePolicy.new(users(:medusa_user),
                                  agent_types(:one)).destroy?
    end

    test "destroy?() does not authorize normal users" do
      assert !AgentTypePolicy.new(users(:normal),
                                  agent_types(:one)).destroy?
    end

    # edit?()

    test "edit?() authorizes Medusa super admins" do
      assert AgentTypePolicy.new(users(:medusa_super_admin),
                                 agent_types(:one)).edit?
    end

    test "edit?() authorizes Medusa admins" do
      assert AgentTypePolicy.new(users(:medusa_admin),
                                 agent_types(:one)).edit?
    end

    test "edit?() does not authorize Medusa users" do
      assert !AgentTypePolicy.new(users(:medusa_user),
                                  agent_types(:one)).edit?
    end

    test "edit?() does not authorize normal users" do
      assert !AgentTypePolicy.new(users(:normal),
                                  agent_types(:one)).edit?
    end

    # index?()

    test "index?() authorizes Medusa super admins" do
      assert AgentTypePolicy.new(users(:medusa_super_admin), AgentType).index?
    end

    test "index?() authorizes Medusa admins" do
      assert AgentTypePolicy.new(users(:medusa_admin), AgentType).index?
    end

    test "index?() does not authorize Medusa users" do
      assert !AgentTypePolicy.new(users(:medusa_user), AgentType).index?
    end

    test "index?() does not authorize normal users" do
      assert !AgentTypePolicy.new(users(:normal), AgentType).index?
    end

    # new?()

    test "new?() authorizes Medusa super admins" do
      assert AgentTypePolicy.new(users(:medusa_super_admin), AgentType).new?
    end

    test "new?() authorizes Medusa admins" do
      assert AgentTypePolicy.new(users(:medusa_admin), AgentType).new?
    end

    test "new?() does not authorize Medusa users" do
      assert !AgentTypePolicy.new(users(:medusa_user), AgentType).new?
    end

    test "new?() does not authorize normal users" do
      assert !AgentTypePolicy.new(users(:normal), AgentType).new?
    end

    # update?()

    test "update?() authorizes Medusa super admins" do
      assert AgentTypePolicy.new(users(:medusa_super_admin),
                                 agent_types(:one)).update?
    end

    test "update?() authorizes Medusa admins" do
      assert AgentTypePolicy.new(users(:medusa_admin),
                                 agent_types(:one)).update?
    end

    test "update?() does not authorize Medusa users" do
      assert !AgentTypePolicy.new(users(:medusa_user),
                                  agent_types(:one)).update?
    end

    test "update?() does not authorize normal users" do
      assert !AgentTypePolicy.new(users(:normal),
                                  agent_types(:one)).update?
    end

  end

end
