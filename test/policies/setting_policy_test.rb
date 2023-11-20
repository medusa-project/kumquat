require 'test_helper'

class SettingPolicyTest < ActiveSupport::TestCase

  # index?()

  test "index?() authorizes Medusa super admins" do
    assert SettingPolicy.new(users(:medusa_super_admin), nil).index?
  end

  test "index?() authorizes Medusa admins" do
    assert SettingPolicy.new(users(:medusa_admin), nil).index?
  end

  test "index?() does not authorize Medusa users" do
    assert !SettingPolicy.new(users(:medusa_user), nil).index?
  end

  test "index?() does not authorize normal users" do
    assert !SettingPolicy.new(users(:normal), nil).index?
  end

  # update?()

  test "update?() authorizes Medusa super admins" do
    assert SettingPolicy.new(users(:medusa_super_admin), nil).update?
  end

  test "update?() authorizes Medusa admins" do
    assert SettingPolicy.new(users(:medusa_admin), nil).update?
  end

  test "update?() does not authorize Medusa users" do
    assert !SettingPolicy.new(users(:medusa_user), nil).update?
  end

  test "update?() does not authorize normal users" do
    assert !SettingPolicy.new(users(:normal), nil).update?
  end

end
