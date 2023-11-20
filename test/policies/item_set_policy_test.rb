require 'test_helper'

class ItemSetPolicyTest < ActiveSupport::TestCase

  # create?()

  test "create?() authorizes Medusa super admins" do
    assert ItemSetPolicy.new(users(:medusa_super_admin), ItemSet).create?
  end

  test "create?() authorizes Medusa admins" do
    assert ItemSetPolicy.new(users(:medusa_admin), ItemSet).create?
  end

  test "create?() authorizes Medusa users" do
    assert ItemSetPolicy.new(users(:medusa_user), ItemSet).create?
  end

  # destroy?()

  test "destroy?() authorizes Medusa super admins" do
    assert ItemSetPolicy.new(users(:medusa_super_admin),
                             item_sets(:one)).destroy?
  end

  test "destroy?() does not authorize admins" do
    assert !ItemSetPolicy.new(users(:medusa_admin),
                              item_sets(:one)).destroy?
  end

  test "destroy?() does not authorize Medusa users" do
    assert !ItemSetPolicy.new(users(:medusa_user),
                              item_sets(:one)).destroy?
  end

  test "destroy?() authorizes related Medusa users" do
    user     = users(:medusa_user)
    item_set = item_sets(:one)
    item_set.users << user
    assert ItemSetPolicy.new(user, item_set).destroy?
  end

  test "destroy?() does not authorize related normal users" do
    user     = users(:normal)
    item_set = item_sets(:one)
    item_set.users << user
    assert !ItemSetPolicy.new(user, item_set).destroy?
  end

  # edit?()

  test "edit?() authorizes Medusa super admins" do
    assert ItemSetPolicy.new(users(:medusa_super_admin),
                             item_sets(:one)).edit?
  end

  test "edit?() does not authorize admins" do
    assert !ItemSetPolicy.new(users(:medusa_admin),
                              item_sets(:one)).edit?
  end

  test "edit?() does not authorize Medusa users" do
    assert !ItemSetPolicy.new(users(:medusa_user),
                              item_sets(:one)).edit?
  end

  test "edit?() authorizes related Medusa users" do
    user     = users(:medusa_user)
    item_set = item_sets(:one)
    item_set.users << user
    assert ItemSetPolicy.new(user, item_set).edit?
  end

  test "edit?() does not authorize related normal users" do
    user     = users(:normal)
    item_set = item_sets(:one)
    item_set.users << user
    assert !ItemSetPolicy.new(user, item_set).edit?
  end

  # items?()

  test "items?() authorizes Medusa super admins" do
    assert ItemSetPolicy.new(users(:medusa_super_admin),
                             item_sets(:one)).items?
  end

  test "items?() does not authorize admins" do
    assert !ItemSetPolicy.new(users(:medusa_admin),
                              item_sets(:one)).items?
  end

  test "items?() does not authorize Medusa users" do
    assert !ItemSetPolicy.new(users(:medusa_user),
                              item_sets(:one)).items?
  end

  test "items?() authorizes related Medusa users" do
    user     = users(:medusa_user)
    item_set = item_sets(:one)
    item_set.users << user
    assert ItemSetPolicy.new(user, item_set).items?
  end

  test "items?() does not authorize related normal users" do
    user     = users(:normal)
    item_set = item_sets(:one)
    item_set.users << user
    assert !ItemSetPolicy.new(user, item_set).items?
  end

  # new?()

  test "new?() authorizes Medusa super admins" do
    assert ItemSetPolicy.new(users(:medusa_super_admin), ItemSet).new?
  end

  test "new?() authorizes admins" do
    assert ItemSetPolicy.new(users(:medusa_admin), ItemSet).new?
  end

  test "new?() authorizes Medusa users" do
    assert ItemSetPolicy.new(users(:medusa_user), ItemSet).new?
  end

  test "new?() authorizes related Medusa users" do
    user     = users(:medusa_user)
    item_set = item_sets(:one)
    item_set.users << user
    assert ItemSetPolicy.new(user, item_set).new?
  end

  test "new?() does not authorize related normal users" do
    user     = users(:normal)
    item_set = item_sets(:one)
    item_set.users << user
    assert !ItemSetPolicy.new(user, item_set).new?
  end

  # remove_all_items?()

  test "remove_all_items?() authorizes Medusa super admins" do
    assert ItemSetPolicy.new(users(:medusa_super_admin),
                             item_sets(:one)).remove_all_items?
  end

  test "remove_all_items?() does not authorize admins" do
    assert !ItemSetPolicy.new(users(:medusa_admin),
                              item_sets(:one)).remove_all_items?
  end

  test "remove_all_items?() does not authorize Medusa users" do
    assert !ItemSetPolicy.new(users(:medusa_user),
                              item_sets(:one)).remove_all_items?
  end

  test "remove_all_items?() authorizes related Medusa users" do
    user     = users(:medusa_user)
    item_set = item_sets(:one)
    item_set.users << user
    assert ItemSetPolicy.new(user, item_set).remove_all_items?
  end

  test "remove_all_items?() does not authorize related normal users" do
    user     = users(:normal)
    item_set = item_sets(:one)
    item_set.users << user
    assert !ItemSetPolicy.new(user, item_set).remove_all_items?
  end

  # remove_items?()

  test "remove_items?() authorizes Medusa super admins" do
    assert ItemSetPolicy.new(users(:medusa_super_admin),
                             item_sets(:one)).remove_items?
  end

  test "remove_items?() does not authorizes Medusa admins" do
    assert !ItemSetPolicy.new(users(:medusa_admin),
                              item_sets(:one)).remove_items?
  end

  test "remove_items?() does not authorize Medusa users" do
    assert !ItemSetPolicy.new(users(:medusa_user),
                              item_sets(:one)).remove_items?
  end

  test "remove_items?() authorizes related Medusa users" do
    user     = users(:medusa_user)
    item_set = item_sets(:one)
    item_set.users << user
    assert ItemSetPolicy.new(user, item_set).remove_items?
  end

  test "remove_items?() does not authorize related normal users" do
    user     = users(:normal)
    item_set = item_sets(:one)
    item_set.users << user
    assert !ItemSetPolicy.new(user, item_set).remove_items?
  end

  # show?()

  test "show?() authorizes Medusa super admins" do
    assert ItemSetPolicy.new(users(:medusa_super_admin),
                             item_sets(:one)).show?
  end

  test "show?() does not authorize admins" do
    assert !ItemSetPolicy.new(users(:medusa_admin),
                              item_sets(:one)).show?
  end

  test "show?() does not authorize Medusa users" do
    assert !ItemSetPolicy.new(users(:medusa_user),
                              item_sets(:one)).show?
  end

  test "show?() authorizes related Medusa users" do
    user     = users(:medusa_user)
    item_set = item_sets(:one)
    item_set.users << user
    assert ItemSetPolicy.new(user, item_set).show?
  end

  test "show?() does not authorize related normal users" do
    user     = users(:normal)
    item_set = item_sets(:one)
    item_set.users << user
    assert !ItemSetPolicy.new(user, item_set).show?
  end

  # update?()

  test "update?() authorizes Medusa super admins" do
    assert ItemSetPolicy.new(users(:medusa_super_admin),
                             item_sets(:one)).update?
  end

  test "update?() does not authorize admins" do
    assert !ItemSetPolicy.new(users(:medusa_admin),
                              item_sets(:one)).update?
  end

  test "update?() does not authorize unrelated Medusa users" do
    assert !ItemSetPolicy.new(users(:medusa_user),
                              item_sets(:one)).update?
  end

  test "update?() authorizes related Medusa users" do
    user     = users(:medusa_user)
    item_set = item_sets(:one)
    item_set.users << user
    assert ItemSetPolicy.new(user, item_set).update?
  end

  test "update?() does not authorize related normal users" do
    user     = users(:normal)
    item_set = item_sets(:one)
    item_set.users << user
    assert !ItemSetPolicy.new(user, item_set).update?
  end

end
