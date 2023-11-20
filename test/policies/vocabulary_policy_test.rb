require 'test_helper'

class VocabularyPolicyTest < ActiveSupport::TestCase

  # create?()

  test "create?() authorizes Medusa super admins" do
    assert VocabularyPolicy.new(users(:medusa_super_admin), Vocabulary).create?
  end

  test "create?() authorizes Medusa admins" do
    assert VocabularyPolicy.new(users(:medusa_admin), Vocabulary).create?
  end

  test "create?() does not authorize Medusa users" do
    assert !VocabularyPolicy.new(users(:medusa_user), Vocabulary).create?
  end

  test "create?() does not authorize normal users" do
    assert !VocabularyPolicy.new(users(:normal), Vocabulary).create?
  end

  # delete_vocabulary_terms?()

  test "delete_vocabulary_terms?() authorizes Medusa super admins" do
    assert VocabularyPolicy.new(users(:medusa_super_admin),
                                vocabularies(:lcsh)).delete_vocabulary_terms?
  end

  test "delete_vocabulary_terms?() authorizes Medusa admins" do
    assert VocabularyPolicy.new(users(:medusa_admin),
                                vocabularies(:lcsh)).delete_vocabulary_terms?
  end

  test "delete_vocabulary_terms?() does not authorize Medusa users" do
    assert !VocabularyPolicy.new(users(:medusa_user),
                                 vocabularies(:lcsh)).delete_vocabulary_terms?
  end

  test "delete_vocabulary_terms?() does not authorize normal users" do
    assert !VocabularyPolicy.new(users(:normal),
                                 vocabularies(:lcsh)).delete_vocabulary_terms?
  end

  test "delete_vocabulary_terms?() does not authorize read-only vocabularies" do
    assert !VocabularyPolicy.new(users(:medusa_super_admin),
                                 vocabularies(:uncontrolled)).delete_vocabulary_terms?
  end

  # destroy?()

  test "destroy?() authorizes Medusa super admins" do
    assert VocabularyPolicy.new(users(:medusa_super_admin),
                                vocabularies(:lcsh)).destroy?
  end

  test "destroy?() authorizes Medusa admins" do
    assert VocabularyPolicy.new(users(:medusa_admin),
                                vocabularies(:lcsh)).destroy?
  end

  test "destroy?() does not authorize Medusa users" do
    assert !VocabularyPolicy.new(users(:medusa_user),
                                 vocabularies(:lcsh)).destroy?
  end

  test "destroy?() does not authorize normal users" do
    assert !VocabularyPolicy.new(users(:normal),
                                 vocabularies(:lcsh)).destroy?
  end

  test "destroy?() does not authorize read-only vocabularies" do
    assert !VocabularyPolicy.new(users(:medusa_super_admin),
                                 vocabularies(:uncontrolled)).destroy?
  end

  # edit?()

  test "edit?() authorizes Medusa super admins" do
    assert VocabularyPolicy.new(users(:medusa_super_admin),
                                vocabularies(:lcsh)).edit?
  end

  test "edit?() authorizes Medusa admins" do
    assert VocabularyPolicy.new(users(:medusa_admin),
                                vocabularies(:lcsh)).edit?
  end

  test "edit?() does not authorize Medusa users" do
    assert !VocabularyPolicy.new(users(:medusa_user),
                                 vocabularies(:lcsh)).edit?
  end

  test "edit?() does not authorize normal users" do
    assert !VocabularyPolicy.new(users(:normal),
                                 vocabularies(:lcsh)).edit?
  end

  test "edit?() does not authorize read-only vocabularies" do
    assert !VocabularyPolicy.new(users(:medusa_super_admin),
                                 vocabularies(:uncontrolled)).edit?
  end

  # import?()

  test "import?() authorizes Medusa super admins" do
    assert VocabularyPolicy.new(users(:medusa_super_admin), Vocabulary).import?
  end

  test "import?() authorizes Medusa admins" do
    assert VocabularyPolicy.new(users(:medusa_admin), Vocabulary).import?
  end

  test "import?() does not authorize Medusa users" do
    assert !VocabularyPolicy.new(users(:medusa_user), Vocabulary).import?
  end

  test "import?() does not authorize normal users" do
    assert !VocabularyPolicy.new(users(:normal), Vocabulary).import?
  end

  # index?()

  test "index?() authorizes Medusa super admins" do
    assert VocabularyPolicy.new(users(:medusa_super_admin), Vocabulary).index?
  end

  test "index?() authorizes Medusa admins" do
    assert VocabularyPolicy.new(users(:medusa_admin), Vocabulary).index?
  end

  test "index?() does not authorize Medusa users" do
    assert !VocabularyPolicy.new(users(:medusa_user), Vocabulary).index?
  end

  test "index?() does not authorize normal users" do
    assert !VocabularyPolicy.new(users(:normal), Vocabulary).index?
  end

  # new?()

  test "new?() authorizes Medusa super admins" do
    assert VocabularyPolicy.new(users(:medusa_super_admin), Vocabulary).new?
  end

  test "new?() authorizes Medusa admins" do
    assert VocabularyPolicy.new(users(:medusa_admin), Vocabulary).new?
  end

  test "new?() does not authorize Medusa users" do
    assert !VocabularyPolicy.new(users(:medusa_user), Vocabulary).new?
  end

  test "new?() does not authorize normal users" do
    assert !VocabularyPolicy.new(users(:normal), Vocabulary).new?
  end

  # show?()

  test "show?() authorizes Medusa super admins" do
    assert VocabularyPolicy.new(users(:medusa_super_admin),
                                vocabularies(:uncontrolled)).show?
  end

  test "show?() authorizes Medusa admins" do
    assert VocabularyPolicy.new(users(:medusa_admin),
                                vocabularies(:uncontrolled)).show?
  end

  test "show?() does not authorize Medusa users" do
    assert !VocabularyPolicy.new(users(:medusa_user),
                                 vocabularies(:uncontrolled)).show?
  end

  test "show?() does not authorize normal users" do
    assert !VocabularyPolicy.new(users(:normal),
                                 vocabularies(:uncontrolled)).show?
  end

  # update?()

  test "update?() authorizes Medusa super admins" do
    assert VocabularyPolicy.new(users(:medusa_super_admin),
                                vocabularies(:lcsh)).update?
  end

  test "update?() authorizes Medusa admins" do
    assert VocabularyPolicy.new(users(:medusa_admin),
                                vocabularies(:lcsh)).update?
  end

  test "update?() does not authorize Medusa users" do
    assert !VocabularyPolicy.new(users(:medusa_user),
                                 vocabularies(:lcsh)).update?
  end

  test "update?() does not authorize normal users" do
    assert !VocabularyPolicy.new(users(:normal),
                                 vocabularies(:lcsh)).update?
  end

  test "update?() does not authorize read-only vocabularies" do
    assert !VocabularyPolicy.new(users(:medusa_super_admin),
                                 vocabularies(:uncontrolled)).update?
  end

end
