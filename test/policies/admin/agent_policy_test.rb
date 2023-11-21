require 'test_helper'

module Admin

  class AgentPolicyTest < ActiveSupport::TestCase

    # create?()

    test "create?() authorizes Medusa super admins" do
      assert AgentPolicy.new(users(:medusa_super_admin), Agent).create?
    end

    test "create?() authorizes Medusa admins" do
      assert AgentPolicy.new(users(:medusa_admin), Agent).create?
    end

    test "create?() does not authorize Medusa users" do
      assert !AgentPolicy.new(users(:medusa_user), Agent).create?
    end

    test "create?() does not authorize normal users" do
      assert !AgentPolicy.new(users(:normal), Agent).create?
    end

    # destroy?()

    test "destroy?() authorizes Medusa super admins" do
      assert AgentPolicy.new(users(:medusa_super_admin),
                             agents(:one)).destroy?
    end

    test "destroy?() authorizes Medusa admins" do
      assert AgentPolicy.new(users(:medusa_admin),
                             agents(:one)).destroy?
    end

    test "destroy?() does not authorize Medusa users" do
      assert !AgentPolicy.new(users(:medusa_user),
                              agents(:one)).destroy?
    end

    test "destroy?() does not authorize normal users" do
      assert !AgentPolicy.new(users(:normal),
                              agents(:one)).destroy?
    end

    # edit?()

    test "edit?() authorizes Medusa super admins" do
      assert AgentPolicy.new(users(:medusa_super_admin),
                             agents(:one)).edit?
    end

    test "edit?() authorizes Medusa admins" do
      assert AgentPolicy.new(users(:medusa_admin),
                             agents(:one)).edit?
    end

    test "edit?() does not authorize Medusa users" do
      assert !AgentPolicy.new(users(:medusa_user),
                              agents(:one)).edit?
    end

    test "edit?() does not authorize normal users" do
      assert !AgentPolicy.new(users(:normal),
                              agents(:one)).edit?
    end

    # index?()

    test "index?() authorizes Medusa super admins" do
      assert AgentPolicy.new(users(:medusa_super_admin), Agent).index?
    end

    test "index?() authorizes Medusa admins" do
      assert AgentPolicy.new(users(:medusa_admin), Agent).index?
    end

    test "index?() does not authorize Medusa users" do
      assert !AgentPolicy.new(users(:medusa_user), Agent).index?
    end

    test "index?() does not authorize normal users" do
      assert !AgentPolicy.new(users(:normal), Agent).index?
    end

    # new?()

    test "new?() authorizes Medusa super admins" do
      assert AgentPolicy.new(users(:medusa_super_admin), Agent).new?
    end

    test "new?() authorizes Medusa admins" do
      assert AgentPolicy.new(users(:medusa_admin), Agent).new?
    end

    test "new?() does not authorize Medusa users" do
      assert !AgentPolicy.new(users(:medusa_user), Agent).new?
    end

    test "new?() does not authorize normal users" do
      assert !AgentPolicy.new(users(:normal), Agent).new?
    end

    # show?()

    test "show?() authorizes Medusa super admins" do
      assert AgentPolicy.new(users(:medusa_super_admin),
                             agents(:one)).show?
    end

    test "show?() authorizes Medusa admins" do
      assert AgentPolicy.new(users(:medusa_admin),
                             agents(:one)).show?
    end

    test "show?() does not authorize Medusa users" do
      assert !AgentPolicy.new(users(:medusa_user),
                              agents(:one)).show?
    end

    test "show?() does not authorize normal users" do
      assert !AgentPolicy.new(users(:normal),
                              agents(:one)).show?
    end

    # update?()

    test "update?() authorizes Medusa super admins" do
      assert AgentPolicy.new(users(:medusa_super_admin),
                             agents(:one)).update?
    end

    test "update?() authorizes Medusa admins" do
      assert AgentPolicy.new(users(:medusa_admin),
                             agents(:one)).update?
    end

    test "update?() does not authorize Medusa users" do
      assert !AgentPolicy.new(users(:medusa_user),
                              agents(:one)).update?
    end

    test "update?() does not authorize normal users" do
      assert !AgentPolicy.new(users(:normal),
                              agents(:one)).update?
    end

  end

end
