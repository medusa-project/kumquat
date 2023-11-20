require 'test_helper'

class StatisticPolicyTest < ActiveSupport::TestCase

  # index?()

  test "index?() authorizes Medusa super admins" do
    assert StatisticPolicy.new(users(:medusa_super_admin), nil).index?
  end

  test "index?() authorizes Medusa admins" do
    assert StatisticPolicy.new(users(:medusa_admin), nil).index?
  end

  test "index?() authorizes Medusa users" do
    assert StatisticPolicy.new(users(:medusa_user), nil).index?
  end

  test "index?() does not authorize normal users" do
    assert !StatisticPolicy.new(users(:normal), nil).index?
  end

end
