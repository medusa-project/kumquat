require 'test_helper'

module Admin

  class ItemPolicyTest < ActiveSupport::TestCase

    # add_items_to_item_set?()

    test "add_items_to_item_set?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).add_items_to_item_set?
    end

    test "add_items_to_item_set?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).add_items_to_item_set?
    end

    test "add_items_to_item_set?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).add_items_to_item_set?
    end

    test "add_items_to_item_set?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).add_items_to_item_set?
    end

    # add_query_to_item_set?()

    test "add_query_to_item_set?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).add_query_to_item_set?
    end

    test "add_query_to_item_set?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).add_query_to_item_set?
    end

    test "add_query_to_item_set?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).add_query_to_item_set?
    end

    test "add_query_to_item_set?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).add_query_to_item_set?
    end

    # batch_change_metadata?()

    test "batch_change_metadata?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).batch_change_metadata?
    end

    test "batch_change_metadata?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).batch_change_metadata?
    end

    test "batch_change_metadata?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).batch_change_metadata?
    end

    test "batch_change_metadata?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).batch_change_metadata?
    end

    # edit_access?()

    test "edit_access?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).edit_access?
    end

    test "edit_access?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).edit_access?
    end

    test "edit_access?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).edit_access?
    end

    test "edit_access?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).edit_access?
    end

    # edit_all?()

    test "edit_all?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).edit_all?
    end

    test "edit_all?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).edit_all?
    end

    test "edit_all?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).edit_all?
    end

    test "edit_all?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).edit_all?
    end

    # edit_info?()

    test "edit_info?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).edit_info?
    end

    test "edit_info?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).edit_info?
    end

    test "edit_info?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).edit_info?
    end

    test "edit_info?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).edit_info?
    end

    # edit_metadata?()

    test "edit_metadata?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).edit_metadata?
    end

    test "edit_metadata?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).edit_metadata?
    end

    test "edit_metadata?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).edit_metadata?
    end

    test "edit_metadata?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).edit_metadata?
    end

    # edit_representation?()

    test "edit_representation?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).edit_representation?
    end

    test "edit_representation?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).edit_representation?
    end

    test "edit_representation?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).edit_representation?
    end

    test "edit_representation?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).edit_representation?
    end

    # enable_full_text_search?()

    test "enable_full_text_search?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).enable_full_text_search?
    end

    test "enable_full_text_search?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).enable_full_text_search?
    end

    test "enable_full_text_search?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).enable_full_text_search?
    end

    test "enable_full_text_search?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).enable_full_text_search?
    end

    # disable_full_text_search?()

    test "disable_full_text_search?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).disable_full_text_search?
    end

    test "disable_full_text_search?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).disable_full_text_search?
    end

    test "disable_full_text_search?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).disable_full_text_search?
    end

    test "disable_full_text_search?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).disable_full_text_search?
    end

    # import?()

    test "import?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin), Item).import?
    end

    test "import?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin), Item).import?
    end

    test "import?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user), Item).import?
    end

    test "import?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal), Item).import?
    end

    # import_embedded_file_metadata?()

    test "import_embedded_file_metadata?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin), Item).import_embedded_file_metadata?
    end

    test "import_embedded_file_metadata?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin), Item).import_embedded_file_metadata?
    end

    test "import_embedded_file_metadata?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user), Item).import_embedded_file_metadata?
    end

    test "import_embedded_file_metadata?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal), Item).import_embedded_file_metadata?
    end

    # index?()

    test "index?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin), Item).index?
    end

    test "index?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin), Item).index?
    end

    test "index?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user), Item).index?
    end

    test "index?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal), Item).index?
    end

    # migrate_metadata?()

    test "migrate_metadata?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).migrate_metadata?
    end

    test "migrate_metadata?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).migrate_metadata?
    end

    test "migrate_metadata?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).migrate_metadata?
    end

    test "migrate_metadata?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).migrate_metadata?
    end

    # publicize_child_binaries?()

    test "publicize_child_binaries?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).publicize_child_binaries?
    end

    test "publicize_child_binaries?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).publicize_child_binaries?
    end

    test "publicize_child_binaries?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).publicize_child_binaries?
    end

    test "publicize_child_binaries?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).publicize_child_binaries?
    end

    # publish?()

    test "publish?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).publish?
    end

    test "publish?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).publish?
    end

    test "publish?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).publish?
    end

    test "publish?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).publish?
    end

    # purge_cached_images?()

    test "purge_cached_images?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).purge_cached_images?
    end

    test "purge_cached_images?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).purge_cached_images?
    end

    test "purge_cached_images?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).purge_cached_images?
    end

    test "purge_cached_images?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).purge_cached_images?
    end

    # replace_metadata?()

    test "replace_metadata?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).replace_metadata?
    end

    test "replace_metadata?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).replace_metadata?
    end

    test "replace_metadata?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).replace_metadata?
    end

    test "replace_metadata?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).replace_metadata?
    end

    # run_ocr?()

    test "run_ocr?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).run_ocr?
    end

    test "run_ocr?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).run_ocr?
    end

    test "run_ocr?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).run_ocr?
    end

    test "run_ocr?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).run_ocr?
    end

    # show?()

    test "show?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).show?
    end

    test "show?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).show?
    end

    test "show?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).show?
    end

    test "show?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).show?
    end

    # sync?()

    test "sync?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin), Item).sync?
    end

    test "sync?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin), Item).sync?
    end

    test "sync?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user), Item).sync?
    end

    test "sync?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal), Item).sync?
    end

    # unpublicize_child_binaries?()

    test "unpublicize_child_binaries?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).unpublicize_child_binaries?
    end

    test "unpublicize_child_binaries?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).unpublicize_child_binaries?
    end

    test "unpublicize_child_binaries?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).unpublicize_child_binaries?
    end

    test "unpublicize_child_binaries?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).unpublicize_child_binaries?
    end

    # unpublish?()

    test "unpublish?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).unpublish?
    end

    test "unpublish?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).unpublish?
    end

    test "unpublish?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).unpublish?
    end

    test "unpublish?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).unpublish?
    end

    # update?()

    test "update?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin),
                            items(:compound_object_1001)).update?
    end

    test "update?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin),
                            items(:compound_object_1001)).update?
    end

    test "update?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user),
                            items(:compound_object_1001)).update?
    end

    test "update?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal),
                             items(:compound_object_1001)).update?
    end

    # update_all?()

    test "update_all?() authorizes Medusa super admins" do
      assert ItemPolicy.new(users(:medusa_super_admin), Item).update_all?
    end

    test "update_all?() authorizes Medusa admins" do
      assert ItemPolicy.new(users(:medusa_admin), Item).update_all?
    end

    test "update_all?() authorizes Medusa users" do
      assert ItemPolicy.new(users(:medusa_user), Item).update_all?
    end

    test "update_all?() does not authorize normal users" do
      assert !ItemPolicy.new(users(:normal), Item).update_all?
    end

  end

end
