require 'test_helper'

module Admin

  class AgentRelationPolicyTest < ActiveSupport::TestCase

    # create?()

    test "create?() authorizes Medusa super admins" do
      assert AgentRelationPolicy.new(users(:medusa_super_admin),
                                     AgentRelation).create?
    end

    test "create?() authorizes Medusa admins" do
      assert AgentRelationPolicy.new(users(:medusa_admin),
                                     AgentRelation).create?
    end

    test "create?() does not authorize Medusa users" do
      assert !AgentRelationPolicy.new(users(:medusa_user),
                                      AgentRelation).create?
    end

    test "create?() does not authorize normal users" do
      assert !AgentRelationPolicy.new(users(:normal),
                                      AgentRelation).create?
    end

    # destroy?()

    test "destroy?() authorizes Medusa super admins" do
      assert AgentRelationPolicy.new(users(:medusa_super_admin),
                                     agent_relations(:one)).destroy?
    end

    test "destroy?() authorizes Medusa admins" do
      assert AgentRelationPolicy.new(users(:medusa_admin),
                                     agent_relations(:one)).destroy?
    end

    test "destroy?() does not authorize Medusa users" do
      assert !AgentRelationPolicy.new(users(:medusa_user),
                                      agent_relations(:one)).destroy?
    end

    test "destroy?() does not authorize normal users" do
      assert !AgentRelationPolicy.new(users(:normal),
                                      agent_relations(:one)).destroy?
    end

    # edit?()

    test "edit?() authorizes Medusa super admins" do
      assert AgentRelationPolicy.new(users(:medusa_super_admin),
                                     agent_relations(:one)).edit?
    end

    test "edit?() authorizes Medusa admins" do
      assert AgentRelationPolicy.new(users(:medusa_admin),
                                     agent_relations(:one)).edit?
    end

    test "edit?() does not authorize Medusa users" do
      assert !AgentRelationPolicy.new(users(:medusa_user),
                                      agent_relations(:one)).edit?
    end

    test "edit?() does not authorize normal users" do
      assert !AgentRelationPolicy.new(users(:normal),
                                      agent_relations(:one)).edit?
    end

    # new?()

    test "new?() authorizes Medusa super admins" do
      assert AgentRelationPolicy.new(users(:medusa_super_admin),
                                     AgentRelation).new?
    end

    test "new?() authorizes Medusa admins" do
      assert AgentRelationPolicy.new(users(:medusa_admin),
                                     AgentRelation).new?
    end

    test "new?() does not authorize Medusa users" do
      assert !AgentRelationPolicy.new(users(:medusa_user),
                                      AgentRelation).new?
    end

    test "new?() does not authorize normal users" do
      assert !AgentRelationPolicy.new(users(:normal),
                                      AgentRelation).new?
    end

    # update?()

    test "update?() authorizes Medusa super admins" do
      assert AgentRelationPolicy.new(users(:medusa_super_admin),
                                     agent_relations(:one)).update?
    end

    test "update?() authorizes Medusa admins" do
      assert AgentRelationPolicy.new(users(:medusa_admin),
                                     agent_relations(:one)).update?
    end

    test "update?() does not authorize Medusa users" do
      assert !AgentRelationPolicy.new(users(:medusa_user),
                                      agent_relations(:one)).update?
    end

    test "update?() does not authorize normal users" do
      assert !AgentRelationPolicy.new(users(:normal),
                                      agent_relations(:one)).update?
    end

  end

end
