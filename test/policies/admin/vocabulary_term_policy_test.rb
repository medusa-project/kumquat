require 'test_helper'

module Admin

  class VocabularyTermPolicyTest < ActiveSupport::TestCase

    # create?()

    test "create?() authorizes Medusa super admins" do
      assert VocabularyTermPolicy.new(users(:medusa_super_admin),
                                      VocabularyTerm).create?
    end

    test "create?() authorizes Medusa admins" do
      assert VocabularyTermPolicy.new(users(:medusa_admin),
                                      VocabularyTerm).create?
    end

    test "create?() does not authorize Medusa users" do
      assert !VocabularyTermPolicy.new(users(:medusa_user),
                                       VocabularyTerm).create?
    end

    test "create?() does not authorize normal users" do
      assert !VocabularyTermPolicy.new(users(:normal),
                                       VocabularyTerm).create?
    end

    # destroy?()

    test "destroy?() authorizes Medusa super admins" do
      assert VocabularyTermPolicy.new(users(:medusa_super_admin),
                                      vocabulary_terms(:one)).destroy?
    end

    test "destroy?() authorizes Medusa admins" do
      assert VocabularyTermPolicy.new(users(:medusa_admin),
                                      vocabulary_terms(:one)).destroy?
    end

    test "destroy?() does not authorize Medusa users" do
      assert !VocabularyTermPolicy.new(users(:medusa_user),
                                       vocabulary_terms(:one)).destroy?
    end

    test "destroy?() does not authorize normal users" do
      assert !VocabularyTermPolicy.new(users(:normal),
                                       vocabulary_terms(:one)).destroy?
    end

    # edit?()

    test "edit?() authorizes Medusa super admins" do
      assert VocabularyTermPolicy.new(users(:medusa_super_admin),
                                      vocabulary_terms(:one)).edit?
    end

    test "edit?() authorizes Medusa admins" do
      assert VocabularyTermPolicy.new(users(:medusa_admin),
                                      vocabulary_terms(:one)).edit?
    end

    test "edit?() does not authorize Medusa users" do
      assert !VocabularyTermPolicy.new(users(:medusa_user),
                                       vocabulary_terms(:one)).edit?
    end

    test "edit?() does not authorize normal users" do
      assert !VocabularyTermPolicy.new(users(:normal),
                                       vocabulary_terms(:one)).edit?
    end

    # index?()

    test "index?() authorizes Medusa super admins" do
      assert VocabularyPolicy.new(users(:medusa_super_admin),
                                  VocabularyTerm).index?
    end

    test "index?() authorizes Medusa admins" do
      assert VocabularyPolicy.new(users(:medusa_admin),
                                  VocabularyTerm).index?
    end

    test "index?() does not authorize Medusa users" do
      assert !VocabularyPolicy.new(users(:medusa_user),
                                   VocabularyTerm).index?
    end

    test "index?() does not authorize normal users" do
      assert !VocabularyPolicy.new(users(:normal),
                                   VocabularyTerm).index?
    end

    # update?()

    test "update?() authorizes Medusa super admins" do
      assert VocabularyTermPolicy.new(users(:medusa_super_admin),
                                      vocabulary_terms(:one)).update?
    end

    test "update?() authorizes Medusa admins" do
      assert VocabularyTermPolicy.new(users(:medusa_admin),
                                      vocabulary_terms(:one)).update?
    end

    test "update?() does not authorize Medusa users" do
      assert !VocabularyTermPolicy.new(users(:medusa_user),
                                       vocabulary_terms(:one)).update?
    end

    test "update?() does not authorize normal users" do
      assert !VocabularyTermPolicy.new(users(:normal),
                                       vocabulary_terms(:one)).update?
    end

  end

end
