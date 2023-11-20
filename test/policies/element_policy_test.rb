require 'test_helper'

class ElementPolicyTest < ActiveSupport::TestCase

  # create?()

  test "create?() authorizes Medusa super admins" do
    assert ElementPolicy.new(users(:medusa_super_admin), Element).create?
  end

  test "create?() authorizes Medusa admins" do
    assert ElementPolicy.new(users(:medusa_admin), Element).create?
  end

  test "create?() does not authorize Medusa users" do
    assert !ElementPolicy.new(users(:medusa_user), Element).create?
  end

  test "create?() does not authorize normal users" do
    assert !ElementPolicy.new(users(:normal), Element).create?
  end

  # destroy?()

  test "destroy?() authorizes Medusa super admins" do
    assert ElementPolicy.new(users(:medusa_super_admin),
                             elements(:title)).destroy?
  end

  test "destroy?() authorizes Medusa admins" do
    assert ElementPolicy.new(users(:medusa_admin),
                             elements(:title)).destroy?
  end

  test "destroy?() does not authorize Medusa users" do
    assert !ElementPolicy.new(users(:medusa_user),
                              elements(:title)).destroy?
  end

  test "destroy?() does not authorize normal users" do
    assert !ElementPolicy.new(users(:normal),
                              elements(:title)).destroy?
  end

  # edit?()

  test "edit?() authorizes Medusa super admins" do
    assert ElementPolicy.new(users(:medusa_super_admin),
                             elements(:title)).edit?
  end

  test "edit?() authorizes Medusa admins" do
    assert ElementPolicy.new(users(:medusa_admin),
                             elements(:title)).edit?
  end

  test "edit?() does not authorize Medusa users" do
    assert !ElementPolicy.new(users(:medusa_user),
                              elements(:title)).edit?
  end

  test "edit?() does not authorize normal users" do
    assert !ElementPolicy.new(users(:normal),
                              elements(:title)).edit?
  end

  # import?()

  test "import?() authorizes Medusa super admins" do
    assert ElementPolicy.new(users(:medusa_super_admin), Element).import?
  end

  test "import?() authorizes Medusa admins" do
    assert ElementPolicy.new(users(:medusa_admin), Element).import?
  end

  test "import?() does not authorize Medusa users" do
    assert !ElementPolicy.new(users(:medusa_user), Element).import?
  end

  test "import?() does not authorize normal users" do
    assert !ElementPolicy.new(users(:normal), Element).import?
  end

  # index?()

  test "index?() authorizes Medusa super admins" do
    assert ElementPolicy.new(users(:medusa_super_admin), Element).index?
  end

  test "index?() authorizes Medusa admins" do
    assert ElementPolicy.new(users(:medusa_admin), Element).index?
  end

  test "index?() authorizes Medusa users" do
    assert ElementPolicy.new(users(:medusa_user), Element).index?
  end

  test "index?() does not authorize normal users" do
    assert !ElementPolicy.new(users(:normal), Element).index?
  end

  # new?()

  test "new?() authorizes Medusa super admins" do
    assert ElementPolicy.new(users(:medusa_super_admin), Element).new?
  end

  test "new?() authorizes Medusa admins" do
    assert ElementPolicy.new(users(:medusa_admin), Element).new?
  end

  test "new?() does not authorize Medusa users" do
    assert !ElementPolicy.new(users(:medusa_user), Element).new?
  end

  test "new?() does not authorize normal users" do
    assert !ElementPolicy.new(users(:normal), Element).new?
  end

  # show?()

  test "show?() authorizes Medusa super admins" do
    assert ElementPolicy.new(users(:medusa_super_admin),
                             elements(:title)).show?
  end

  test "show?() authorizes Medusa admins" do
    assert ElementPolicy.new(users(:medusa_admin),
                             elements(:title)).show?
  end

  test "show?() authorizes Medusa users" do
    assert ElementPolicy.new(users(:medusa_user),
                             elements(:title)).show?
  end

  test "show?() does not authorize normal users" do
    assert !ElementPolicy.new(users(:normal),
                              elements(:title)).show?
  end

  # update?()

  test "update?() authorizes Medusa super admins" do
    assert ElementPolicy.new(users(:medusa_super_admin),
                             elements(:title)).update?
  end

  test "update?() authorizes Medusa admins" do
    assert ElementPolicy.new(users(:medusa_admin),
                             elements(:title)).update?
  end

  test "update?() does not authorize Medusa users" do
    assert !ElementPolicy.new(users(:medusa_user),
                              elements(:title)).update?
  end

  test "update?() does not authorize normal users" do
    assert !ElementPolicy.new(users(:normal),
                              elements(:title)).update?
  end

  # usages?()

  test "usages?() authorizes Medusa super admins" do
    assert ElementPolicy.new(users(:medusa_super_admin),
                             elements(:title)).usages?
  end

  test "usages?() authorizes Medusa admins" do
    assert ElementPolicy.new(users(:medusa_admin),
                             elements(:title)).usages?
  end

  test "usages?() authorizes Medusa users" do
    assert ElementPolicy.new(users(:medusa_user),
                             elements(:title)).usages?
  end

  test "usages?() does not authorize normal users" do
    assert !ElementPolicy.new(users(:normal),
                              elements(:title)).usages?
  end

end
