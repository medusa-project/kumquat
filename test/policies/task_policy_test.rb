require 'test_helper'

class TaskPolicyTest < ActiveSupport::TestCase

  # index?()

  test "index?() authorizes Medusa super admins" do
    assert TaskPolicy.new(users(:medusa_super_admin), Task).index?
  end

  test "index?() authorizes Medusa admins" do
    assert TaskPolicy.new(users(:medusa_admin), Task).index?
  end

  test "index?() authorizes Medusa users" do
    assert TaskPolicy.new(users(:medusa_user), Task).index?
  end

  test "index?() does not authorize normal users" do
    assert !TaskPolicy.new(users(:normal), Task).index?
  end

  # show?()

  test "show?() authorizes Medusa super admins" do
    assert TaskPolicy.new(users(:medusa_super_admin),
                          tasks(:waiting)).show?
  end

  test "show?() authorizes Medusa admins" do
    assert TaskPolicy.new(users(:medusa_admin),
                          tasks(:waiting)).show?
  end

  test "show?() authorizes Medusa users" do
    assert TaskPolicy.new(users(:medusa_user),
                          tasks(:waiting)).show?
  end

  test "show?() does not authorize normal users" do
    assert !TaskPolicy.new(users(:normal),
                           tasks(:waiting)).show?
  end

end
