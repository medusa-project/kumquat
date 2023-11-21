require 'test_helper'

module Admin

  class BinaryPolicyTest < ActiveSupport::TestCase

    # edit_access?()

    test "edit_access?() authorizes Medusa super admins" do
      assert BinaryPolicy.new(users(:medusa_super_admin),
                              binaries(:compound_object_1001_access)).edit_access?
    end

    test "edit_access?() authorizes Medusa admins" do
      assert BinaryPolicy.new(users(:medusa_admin),
                              binaries(:compound_object_1001_access)).edit_access?
    end

    test "edit_access?() does not authorize Medusa users" do
      assert !BinaryPolicy.new(users(:medusa_user),
                               binaries(:compound_object_1001_access)).edit_access?
    end

    test "edit_access?() does not authorize normal users" do
      assert !BinaryPolicy.new(users(:normal),
                               binaries(:compound_object_1001_access)).edit_access?
    end

    # run_ocr?()

    test "run_ocr?() authorizes Medusa super admins" do
      assert BinaryPolicy.new(users(:medusa_super_admin),
                              binaries(:compound_object_1001_access)).run_ocr?
    end

    test "run_ocr?() authorizes Medusa admins" do
      assert BinaryPolicy.new(users(:medusa_admin),
                              binaries(:compound_object_1001_access)).run_ocr?
    end

    test "run_ocr?() authorizes Medusa users" do
      assert BinaryPolicy.new(users(:medusa_user),
                              binaries(:compound_object_1001_access)).run_ocr?
    end

    test "run_ocr?() does not authorize normal users" do
      assert !BinaryPolicy.new(users(:normal),
                               binaries(:compound_object_1001_access)).run_ocr?
    end

    # update?()

    test "update?() authorizes Medusa super admins" do
      assert BinaryPolicy.new(users(:medusa_super_admin),
                              binaries(:compound_object_1001_access)).update?
    end

    test "update?() authorizes Medusa admins" do
      assert BinaryPolicy.new(users(:medusa_admin),
                              binaries(:compound_object_1001_access)).update?
    end

    test "update?() does not authorize Medusa users" do
      assert !BinaryPolicy.new(users(:medusa_user),
                               binaries(:compound_object_1001_access)).update?
    end

    test "update?() does not authorize normal users" do
      assert !BinaryPolicy.new(users(:normal),
                               binaries(:compound_object_1001_access)).update?
    end

  end

end
