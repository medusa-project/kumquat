require 'test_helper'

class ElementTest < ActiveSupport::TestCase

  # from_json_struct()

  test "from_json_struct() returns a correct instance" do
    struct = {
      name:        "newName",
      description: "Test Description"
    }
    e = Element.from_json_struct(struct)
    assert_equal struct[:name], e.name
    assert_equal struct[:description], e.description
  end

  # destroy()

  test "destroy() fails if the element is in use by any items" do
    e = elements(:title)
    ItemElement.where(name: e.name).destroy_all

    assert_raises ActiveRecord::RecordNotDestroyed do
      e.destroy!
    end
  end

  test "destroy() fails if the element is in use by any metadata profiles" do
    e = elements(:title)
    MetadataProfileElement.where(name: e.name).destroy_all

    assert_raises ActiveRecord::RecordNotDestroyed do
      e.destroy!
    end
  end

  test "destroy() succeeds if the element is not in use by any items nor
  metadata profiles" do
    e = elements(:title)
    MetadataProfileElement.where(name: e.name).destroy_all
    ItemElement.where(name: e.name).destroy_all
    e.destroy!
  end

  # name

  test "name may contain only alphanumerics and dashes" do
    e = elements(:title)
    e.name = "abcABC123"
    assert e.valid?
    e.name = "abc-abc"
    assert e.valid?
    e.name = "abc_abc"
    assert !e.valid?
  end

  test "name may not be changed" do
    e = elements(:title)
    assert_raises ActiveRecord::RecordInvalid do
      e.update!(name: "newName")
    end
  end

  # num_usages_by_items()

  test "num_usages_by_items() returns a correct count" do
    result = elements(:title).num_usages_by_items
    assert result > 1
  end

  # num_usages_by_metadata_profiles()

  test "num_usages_by_metadata_profiles() returns a correct count" do
    result = elements(:title).num_usages_by_metadata_profiles
    assert result > 1
  end

  # update_from_json_struct()

  test "update_from_json_struct() works" do
    struct = {
      name:        "title",
      description: "New Description"
    }
    e = elements(:title)
    e.update_from_json_struct(struct)
    assert_equal struct[:name], e.name
    assert_equal struct[:description], e.description
  end

  # usages()

  test "usages() works" do
    result = elements(:title).usages
    assert_equal 2, result.length
    u = result[0]
    assert_equal collections(:compound_object).repository_id, u['collection_id']
    assert_equal items(:compound_object_1001).repository_id, u['item_id']
    assert_equal "title", u['element_name']
    assert_equal "My Great Title", u['element_value']
    assert_nil u['element_uri']
  end

end
