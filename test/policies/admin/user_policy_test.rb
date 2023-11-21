require 'test_helper'

module Admin

  class UserPolicyTest < ActiveSupport::TestCase

    # create?()

    test "create?() authorizes Medusa super admins" do
      assert UserPolicy.new(users(:medusa_super_admin), User).create?
    end

    test "create?() does not authorize Medusa admins" do
      assert !UserPolicy.new(users(:medusa_admin), User).create?
    end

    test "create?() does not authorize Medusa users" do
      assert !UserPolicy.new(users(:medusa_user), User).create?
    end

    test "create?() does not authorize normal users" do
      assert !UserPolicy.new(users(:normal), User).create?
    end

    # destroy?()

    test "destroy?() authorizes Medusa super admins" do
      assert UserPolicy.new(users(:medusa_super_admin),
                            users(:medusa_user)).destroy?
    end

    test "destroy?() does not authorize Medusa admins" do
      assert !UserPolicy.new(users(:medusa_admin),
                             users(:medusa_user)).destroy?
    end

    test "destroy?() does not authorize Medusa users" do
      assert !UserPolicy.new(users(:medusa_user),
                             users(:medusa_user)).destroy?
    end

    test "destroy?() does not authorize normal users" do
      assert !UserPolicy.new(users(:normal),
                             users(:normal)).destroy?
    end

    # index?()

    test "index?() authorizes Medusa super admins" do
      assert UserPolicy.new(users(:medusa_super_admin), User).index?
    end

    test "index?() does not authorize Medusa admins" do
      assert !UserPolicy.new(users(:medusa_admin), User).index?
    end

    test "index?() does not authorize Medusa users" do
      assert !UserPolicy.new(users(:medusa_user), User).index?
    end

    test "index?() does not authorize normal users" do
      assert !UserPolicy.new(users(:normal), User).index?
    end

    # new?()

    test "new?() authorizes Medusa super admins" do
      assert UserPolicy.new(users(:medusa_super_admin), User).new?
    end

    test "new?() does not authorize Medusa admins" do
      assert !UserPolicy.new(users(:medusa_admin), User).new?
    end

    test "new?() does not authorize Medusa users" do
      assert !UserPolicy.new(users(:medusa_user), User).new?
    end

    test "new?() does not authorize normal users" do
      assert !UserPolicy.new(users(:normal), User).new?
    end

    # reset_api_key?()

    test "reset_api_key?() authorizes Medusa super admins" do
      assert UserPolicy.new(users(:medusa_super_admin),
                            users(:medusa_user)).reset_api_key?
    end

    test "reset_api_key?() does not authorize Medusa admins" do
      assert !UserPolicy.new(users(:medusa_admin),
                             users(:medusa_user)).reset_api_key?
    end

    test "reset_api_key?() authorizes the same Medusa user" do
      assert UserPolicy.new(users(:medusa_user),
                            users(:medusa_user)).reset_api_key?
    end

    test "reset_api_key?() does not authorize normal users" do
      assert !UserPolicy.new(users(:normal),
                             users(:normal)).reset_api_key?
    end

    # show?()

    test "show?() authorizes Medusa super admins" do
      assert UserPolicy.new(users(:medusa_super_admin),
                            users(:medusa_user)).show?
    end

    test "show?() does not authorize Medusa admins" do
      assert !UserPolicy.new(users(:medusa_admin),
                             users(:medusa_user)).show?
    end

    test "show?() does not authorize different normal users" do
      assert !UserPolicy.new(users(:medusa_user),
                             users(:medusa_admin)).show?
    end

    test "show?() authorizes the same Medusa user" do
      assert UserPolicy.new(users(:medusa_user),
                            users(:medusa_user)).show?
    end

    test "show?() does not authorize normal users" do
      assert !UserPolicy.new(users(:normal),
                             users(:normal)).show?
    end

  end

end
