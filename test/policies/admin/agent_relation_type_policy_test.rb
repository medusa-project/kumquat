require 'test_helper'

module Admin

  class AgentRelationTypePolicyTest < ActiveSupport::TestCase

    # create?()

    test "create?() authorizes Medusa super admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_super_admin),
                                         AgentRelationType).create?
    end

    test "create?() authorizes Medusa admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_admin),
                                         AgentRelationType).create?
    end

    test "create?() does not authorize Medusa users" do
      assert !AgentRelationTypePolicy.new(users(:medusa_user),
                                          AgentRelationType).create?
    end

    test "create?() does not authorize normal users" do
      assert !AgentRelationTypePolicy.new(users(:normal),
                                          AgentRelationType).create?
    end

    # destroy?()

    test "destroy?() authorizes Medusa super admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_super_admin),
                                         agent_relation_types(:one)).destroy?
    end

    test "destroy?() authorizes Medusa admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_admin),
                                         agent_relation_types(:one)).destroy?
    end

    test "destroy?() does not authorize Medusa users" do
      assert !AgentRelationTypePolicy.new(users(:medusa_user),
                                          agent_relation_types(:one)).destroy?
    end

    test "destroy?() does not authorize normal users" do
      assert !AgentRelationTypePolicy.new(users(:normal),
                                          agent_relation_types(:one)).destroy?
    end

    # edit?()

    test "edit?() authorizes Medusa super admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_super_admin),
                                         agent_relation_types(:one)).edit?
    end

    test "edit?() authorizes Medusa admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_admin),
                                         agent_relation_types(:one)).edit?
    end

    test "edit?() does not authorize Medusa users" do
      assert !AgentRelationTypePolicy.new(users(:medusa_user),
                                          agent_relation_types(:one)).edit?
    end

    test "edit?() does not authorize normal users" do
      assert !AgentRelationTypePolicy.new(users(:normal),
                                          agent_relation_types(:one)).edit?
    end

    # index?()

    test "index?() authorizes Medusa super admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_super_admin),
                                         AgentRelationType).index?
    end

    test "index?() authorizes Medusa admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_admin),
                                         AgentRelationType).index?
    end

    test "index?() does not authorize Medusa users" do
      assert !AgentRelationTypePolicy.new(users(:medusa_user),
                                          AgentRelationType).index?
    end

    test "index?() does not authorize normal users" do
      assert !AgentRelationTypePolicy.new(users(:normal),
                                          AgentRelationType).index?
    end

    # new?()

    test "new?() authorizes Medusa super admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_super_admin),
                                         AgentRelationType).new?
    end

    test "new?() authorizes Medusa admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_admin),
                                         AgentRelationType).new?
    end

    test "new?() does not authorize Medusa users" do
      assert !AgentRelationTypePolicy.new(users(:medusa_user),
                                          AgentRelationType).new?
    end

    test "new?() does not authorize normal users" do
      assert !AgentRelationTypePolicy.new(users(:normal),
                                          AgentRelationType).new?
    end

    # update?()

    test "update?() authorizes Medusa super admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_super_admin),
                                         agent_relation_types(:one)).update?
    end

    test "update?() authorizes Medusa admins" do
      assert AgentRelationTypePolicy.new(users(:medusa_admin),
                                         agent_relation_types(:one)).update?
    end

    test "update?() does not authorize Medusa users" do
      assert !AgentRelationTypePolicy.new(users(:medusa_user),
                                          agent_relation_types(:one)).update?
    end

    test "update?() does not authorize normal users" do
      assert !AgentRelationTypePolicy.new(users(:normal),
                                          agent_relation_types(:one)).update?
    end

  end

end
