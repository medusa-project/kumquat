require 'test_helper'

class MetadataProfileElementPolicyTest < ActiveSupport::TestCase

  # create?()

  test "create?() authorizes Medusa super admins" do
    assert MetadataProfileElementPolicy.new(users(:medusa_super_admin),
                                            MetadataProfileElement).create?
  end

  test "create?() authorizes Medusa admins" do
    assert MetadataProfileElementPolicy.new(users(:medusa_admin),
                                            MetadataProfileElement).create?
  end

  test "create?() does not authorize Medusa users" do
    assert !MetadataProfileElementPolicy.new(users(:medusa_user),
                                             MetadataProfileElement).create?
  end

  test "create?() does not authorize normal users" do
    assert !MetadataProfileElementPolicy.new(users(:normal),
                                             MetadataProfileElement).create?
  end

  # destroy?()

  test "destroy?() authorizes Medusa super admins" do
    assert MetadataProfileElementPolicy.new(users(:medusa_super_admin),
                                            metadata_profile_elements(:default_profile_title)).destroy?
  end

  test "destroy?() authorizes Medusa admins" do
    assert MetadataProfileElementPolicy.new(users(:medusa_admin),
                                            metadata_profile_elements(:default_profile_title)).destroy?
  end

  test "destroy?() does not authorize Medusa users" do
    assert !MetadataProfileElementPolicy.new(users(:medusa_user),
                                             metadata_profile_elements(:default_profile_title)).destroy?
  end

  test "destroy?() does not authorize normal users" do
    assert !MetadataProfileElementPolicy.new(users(:normal),
                                             metadata_profile_elements(:default_profile_title)).destroy?
  end

  # edit?()

  test "edit?() authorizes Medusa super admins" do
    assert MetadataProfileElementPolicy.new(users(:medusa_super_admin),
                                            metadata_profile_elements(:default_profile_title)).edit?
  end

  test "edit?() authorizes Medusa admins" do
    assert MetadataProfileElementPolicy.new(users(:medusa_admin),
                                            metadata_profile_elements(:default_profile_title)).edit?
  end

  test "edit?() does not authorize Medusa users" do
    assert !MetadataProfileElementPolicy.new(users(:medusa_user),
                                             metadata_profile_elements(:default_profile_title)).edit?
  end

  test "edit?() does not authorize normal users" do
    assert !MetadataProfileElementPolicy.new(users(:normal),
                                             metadata_profile_elements(:default_profile_title)).edit?
  end

  # new?()

  test "new?() authorizes Medusa super admins" do
    assert MetadataProfileElementPolicy.new(users(:medusa_super_admin),
                                            MetadataProfileElement).new?
  end

  test "new?() authorizes Medusa admins" do
    assert MetadataProfileElementPolicy.new(users(:medusa_admin),
                                            MetadataProfileElement).new?
  end

  test "new?() does not authorize Medusa users" do
    assert !MetadataProfileElementPolicy.new(users(:medusa_user),
                                             MetadataProfileElement).new?
  end

  test "new?() does not authorize normal users" do
    assert !MetadataProfileElementPolicy.new(users(:normal),
                                             MetadataProfileElement).new?
  end

  # update?()

  test "update?() authorizes Medusa super admins" do
    assert MetadataProfileElementPolicy.new(users(:medusa_super_admin),
                                            metadata_profile_elements(:default_profile_title)).update?
  end

  test "update?() authorizes Medusa admins" do
    assert MetadataProfileElementPolicy.new(users(:medusa_admin),
                                            metadata_profile_elements(:default_profile_title)).update?
  end

  test "update?() does not authorize Medusa users" do
    assert !MetadataProfileElementPolicy.new(users(:medusa_user),
                                             metadata_profile_elements(:default_profile_title)).update?
  end

  test "update?() does not authorize normal users" do
    assert !MetadataProfileElementPolicy.new(users(:normal),
                                             metadata_profile_elements(:default_profile_title)).update?
  end

end
