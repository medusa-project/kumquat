require 'test_helper'

module Admin

  class MetadataProfilePolicyTest < ActiveSupport::TestCase

    # clone?()

    test "clone?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       metadata_profiles(:default)).clone?
    end

    test "clone?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       metadata_profiles(:default)).clone?
    end

    test "clone?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        metadata_profiles(:default)).clone?
    end

    test "clone?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        metadata_profiles(:default)).clone?
    end

    # create?()

    test "create?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       MetadataProfile).create?
    end

    test "create?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       MetadataProfile).create?
    end

    test "create?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        MetadataProfile).create?
    end

    test "create?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        MetadataProfile).create?
    end

    # delete_elements?()

    test "delete_elements?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       metadata_profiles(:default)).delete_elements?
    end

    test "delete_elements?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       metadata_profiles(:default)).delete_elements?
    end

    test "delete_elements?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        metadata_profiles(:default)).delete_elements?
    end

    test "delete_elements?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        metadata_profiles(:default)).delete_elements?
    end

    # destroy?()

    test "destroy?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       metadata_profiles(:default)).destroy?
    end

    test "destroy?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       metadata_profiles(:default)).destroy?
    end

    test "destroy?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        metadata_profiles(:default)).destroy?
    end

    test "destroy?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        metadata_profiles(:default)).destroy?
    end

    # edit?()

    test "edit?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       metadata_profiles(:default)).edit?
    end

    test "edit?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       metadata_profiles(:default)).edit?
    end

    test "edit?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        metadata_profiles(:default)).edit?
    end

    test "edit?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        metadata_profiles(:default)).edit?
    end

    # import?()

    test "import?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       MetadataProfile).import?
    end

    test "import?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       MetadataProfile).import?
    end

    test "import?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        MetadataProfile).import?
    end

    test "import?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        MetadataProfile).import?
    end

    # index?()

    test "index?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       MetadataProfile).index?
    end

    test "index?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       MetadataProfile).index?
    end

    test "index?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        MetadataProfile).index?
    end

    test "index?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        MetadataProfile).index?
    end

    # new?()

    test "new?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       MetadataProfile).new?
    end

    test "new?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       MetadataProfile).new?
    end

    test "new?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        MetadataProfile).new?
    end

    test "new?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        MetadataProfile).new?
    end

    # reindex_items?()

    test "reindex_items?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       metadata_profiles(:default)).reindex_items?
    end

    test "reindex_items?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       metadata_profiles(:default)).reindex_items?
    end

    test "reindex_items?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        metadata_profiles(:default)).reindex_items?
    end

    test "reindex_items?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        metadata_profiles(:default)).reindex_items?
    end

    # show?()

    test "show?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       metadata_profiles(:default)).show?
    end

    test "show?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       metadata_profiles(:default)).show?
    end

    test "show?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        metadata_profiles(:default)).show?
    end

    test "show?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        metadata_profiles(:default)).show?
    end

    # update?()

    test "update?() authorizes Medusa super admins" do
      assert MetadataProfilePolicy.new(users(:medusa_super_admin),
                                       metadata_profiles(:default)).update?
    end

    test "update?() authorizes Medusa admins" do
      assert MetadataProfilePolicy.new(users(:medusa_admin),
                                       metadata_profiles(:default)).update?
    end

    test "update?() does not authorize Medusa users" do
      assert !MetadataProfilePolicy.new(users(:medusa_user),
                                        metadata_profiles(:default)).update?
    end

    test "update?() does not authorize normal users" do
      assert !MetadataProfilePolicy.new(users(:normal),
                                        metadata_profiles(:default)).update?
    end

  end

end
