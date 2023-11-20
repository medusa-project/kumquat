require 'test_helper'

class HostGroupPolicyTest < ActiveSupport::TestCase

  # create?()

  test "create?() authorizes Medusa super admins" do
    assert HostGroupPolicy.new(users(:medusa_super_admin), HostGroup).create?
  end

  test "create?() authorizes Medusa admins" do
    assert HostGroupPolicy.new(users(:medusa_admin), HostGroup).create?
  end

  test "create?() does not authorize Medusa users" do
    assert !HostGroupPolicy.new(users(:medusa_user), HostGroup).create?
  end

  test "create?() does not authorize normal users" do
    assert !HostGroupPolicy.new(users(:normal), HostGroup).create?
  end

  # destroy?()

  test "destroy?() authorizes Medusa super admins" do
    assert HostGroupPolicy.new(users(:medusa_super_admin),
                               host_groups(:blue)).destroy?
  end

  test "destroy?() authorizes Medusa admins" do
    assert HostGroupPolicy.new(users(:medusa_admin),
                               host_groups(:blue)).destroy?
  end

  test "destroy?() does not authorize Medusa users" do
    assert !HostGroupPolicy.new(users(:medusa_user),
                                host_groups(:blue)).destroy?
  end

  test "destroy?() does not authorize normal users" do
    assert !HostGroupPolicy.new(users(:normal),
                                host_groups(:blue)).destroy?
  end

  # edit?()

  test "edit?() authorizes Medusa super admins" do
    assert HostGroupPolicy.new(users(:medusa_super_admin),
                               host_groups(:blue)).edit?
  end

  test "edit?() authorizes Medusa admins" do
    assert HostGroupPolicy.new(users(:medusa_admin),
                               host_groups(:blue)).edit?
  end

  test "edit?() does not authorize Medusa users" do
    assert !HostGroupPolicy.new(users(:medusa_user),
                                host_groups(:blue)).edit?
  end

  test "edit?() does not authorize normal users" do
    assert !HostGroupPolicy.new(users(:normal),
                                host_groups(:blue)).edit?
  end

  # index?()

  test "index?() authorizes Medusa super admins" do
    assert HostGroupPolicy.new(users(:medusa_super_admin), HostGroup).index?
  end

  test "index?() authorizes Medusa admins" do
    assert HostGroupPolicy.new(users(:medusa_admin), HostGroup).index?
  end

  test "index?() does not authorize Medusa users" do
    assert !HostGroupPolicy.new(users(:medusa_user), HostGroup).index?
  end

  test "index?() does not authorize normal users" do
    assert !HostGroupPolicy.new(users(:normal), HostGroup).index?
  end

  # new?()

  test "new?() authorizes Medusa super admins" do
    assert HostGroupPolicy.new(users(:medusa_super_admin), HostGroup).new?
  end

  test "new?() authorizes Medusa admins" do
    assert HostGroupPolicy.new(users(:medusa_admin), HostGroup).new?
  end

  test "new?() does not authorize Medusa users" do
    assert !HostGroupPolicy.new(users(:medusa_user), HostGroup).new?
  end

  test "new?() does not authorize normal users" do
    assert !HostGroupPolicy.new(users(:normal), HostGroup).new?
  end

  # show?()

  test "show?() authorizes Medusa super admins" do
    assert HostGroupPolicy.new(users(:medusa_super_admin),
                               host_groups(:blue)).show?
  end

  test "show?() authorizes Medusa admins" do
    assert HostGroupPolicy.new(users(:medusa_admin),
                               host_groups(:blue)).show?
  end

  test "show?() does not authorize Medusa users" do
    assert !HostGroupPolicy.new(users(:medusa_user),
                                host_groups(:blue)).show?
  end

  test "show?() does not authorize normal users" do
    assert !HostGroupPolicy.new(users(:normal),
                                host_groups(:blue)).show?
  end

  # update?()

  test "update?() authorizes Medusa super admins" do
    assert HostGroupPolicy.new(users(:medusa_super_admin),
                               host_groups(:blue)).update?
  end

  test "update?() authorizes Medusa admins" do
    assert HostGroupPolicy.new(users(:medusa_admin),
                               host_groups(:blue)).update?
  end

  test "update?() does not authorize Medusa users" do
    assert !HostGroupPolicy.new(users(:medusa_user),
                                host_groups(:blue)).update?
  end

  test "update?() does not authorize normal users" do
    assert !HostGroupPolicy.new(users(:normal),
                                host_groups(:blue)).update?
  end

end
