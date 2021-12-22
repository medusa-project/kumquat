require "test_helper"

class VocabularyTermTest < ActiveSupport::TestCase

  # rights_related()

  test "rights_related() returns all rights-related terms" do
    length = VocabularyTerm.rights_related.length
    assert length > 0
    assert length < 100
  end

  # image()

  test "image() returns a correct value when a corresponding augmented term exists" do
    assert_equal "creative_commons/by.png",
                 vocabulary_terms(:augmented).image
  end

  test "image() returns nil when a corresponding augmented term does not exist" do
    assert_nil vocabulary_terms(:one).image
  end

  # info_uri()

  test "info_uri() returns a correct value when a corresponding augmented term exists" do
    assert_equal "https://creativecommons.org/licenses/by/4.0/",
                 vocabulary_terms(:augmented).info_uri
  end

  test "info_uri() returns nil when a corresponding augmented term does not exist" do
    assert_nil vocabulary_terms(:one).info_uri
  end

  # uri

  test "uri must be unique" do
    voc = vocabularies(:rights)
    VocabularyTerm.create!(vocabulary: voc,
                           string:     "cats",
                           uri:        "http://example.org/1")
    assert_raises ActiveRecord::RecordNotUnique do
      VocabularyTerm.create!(vocabulary: voc,
                             string:     "dogs",
                             uri:        "http://example.org/1")
    end
  end

end
