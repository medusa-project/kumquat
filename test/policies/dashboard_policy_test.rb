require 'test_helper'

class DashboardPolicyTest < ActiveSupport::TestCase

  # index?()

  test "index?() authorizes Medusa super admins" do
    assert DashboardPolicy.new(users(:medusa_super_admin), nil).index?
  end

  test "index?() authorizes Medusa admins" do
    assert DashboardPolicy.new(users(:medusa_admin), nil).index?
  end

  test "index?() authorizes Medusa users" do
    assert DashboardPolicy.new(users(:medusa_user), nil).index?
  end

  test "index?() does not authorize normal users" do
    assert !DashboardPolicy.new(users(:normal), nil).index?
  end

end
