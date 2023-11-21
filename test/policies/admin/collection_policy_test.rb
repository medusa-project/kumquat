require 'test_helper'

module Admin

  class CollectionPolicyTest < ActiveSupport::TestCase

    # delete_items?()

    test "delete_items?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).delete_items?
    end

    test "delete_items?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).delete_items?
    end

    test "delete_items?() does not authorize Medusa users" do
      assert !CollectionPolicy.new(users(:medusa_user),
                                   collections(:compound_object)).delete_items?
    end

    test "delete_items?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).delete_items?
    end

    # edit_access?()

    test "edit_access?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).edit_access?
    end

    test "edit_access?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).edit_access?
    end

    test "edit_access?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).edit_access?
    end

    test "edit_access?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).edit_access?
    end

    # edit_email_watchers?()

    test "edit_email_watchers?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).edit_email_watchers?
    end

    test "edit_email_watchers?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).edit_email_watchers?
    end

    test "edit_email_watchers?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).edit_email_watchers?
    end

    test "edit_email_watchers?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).edit_email_watchers?
    end

    # edit_info?()

    test "edit_info?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).edit_info?
    end

    test "edit_info?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).edit_info?
    end

    test "edit_info?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).edit_info?
    end

    test "edit_info?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).edit_info?
    end

    # edit_representation?()

    test "edit_representation?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).edit_representation?
    end

    test "edit_representation?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).edit_representation?
    end

    test "edit_representation?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).edit_representation?
    end

    test "edit_representation?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).edit_representation?
    end

    # index?()

    test "index?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin), Collection).index?
    end

    test "index?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin), Collection).index?
    end

    test "index?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user), Collection).index?
    end

    test "index?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal), Collection).index?
    end

    # items?()

    test "items?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).items?
    end

    test "items?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).items?
    end

    test "items?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).items?
    end

    test "items?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).items?
    end

    # purge_cached_images?()

    test "purge_cached_images?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).purge_cached_images?
    end

    test "purge_cached_images?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).purge_cached_images?
    end

    test "purge_cached_images?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).purge_cached_images?
    end

    test "purge_cached_images?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).purge_cached_images?
    end

    # show?()

    test "show?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).show?
    end

    test "show?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).show?
    end

    test "show?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).show?
    end

    test "show?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).show?
    end

    # statistics?()

    test "statistics?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).statistics?
    end

    test "statistics?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).statistics?
    end

    test "statistics?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).statistics?
    end

    test "statistics?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).statistics?
    end

    # sync?()

    test "sync?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin), Collection).sync?
    end

    test "sync?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin), Collection).sync?
    end

    test "sync?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user), Collection).sync?
    end

    test "sync?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal), Collection).sync?
    end

    # unwatch?()

    test "unwatch?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).unwatch?
    end

    test "unwatch?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).unwatch?
    end

    test "unwatch?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).unwatch?
    end

    test "unwatch?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).unwatch?
    end

    # update?()

    test "update?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).update?
    end

    test "update?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).update?
    end

    test "update?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).update?
    end

    test "update?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).update?
    end

    # watch?()

    test "watch?() authorizes Medusa super admins" do
      assert CollectionPolicy.new(users(:medusa_super_admin),
                                  collections(:compound_object)).watch?
    end

    test "watch?() authorizes Medusa admins" do
      assert CollectionPolicy.new(users(:medusa_admin),
                                  collections(:compound_object)).watch?
    end

    test "watch?() authorizes Medusa users" do
      assert CollectionPolicy.new(users(:medusa_user),
                                  collections(:compound_object)).watch?
    end

    test "watch?() does not authorize normal users" do
      assert !CollectionPolicy.new(users(:normal),
                                   collections(:compound_object)).watch?
    end

  end

end
