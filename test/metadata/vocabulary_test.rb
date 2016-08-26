require 'test_helper'

class VocabularyTest < ActiveSupport::TestCase

  test 'from_json should work' do
    json = <<-HEREDOC
    {
      "id": 15,
      "key": "rs",
      "name": "RightsStatements.org",
      "created_at": "2016-08-26 15:39:02 UTC",
      "updated_at": "2016-08-26 15:39:02 UTC",
      "vocabulary_terms": [
        {
          "id": 13,
          "string": "Copyright Not Evaluated",
          "uri": "http://rightsstatements.org/vocab/CNE/1.0/",
          "vocabulary_id": 15,
          "created_at": "2016-08-26 15:47:09 UTC",
          "updated_at": "2016-08-26 15:47:09 UTC"
        },
        {
          "id": 14,
          "string": "Copyright Undetermined",
          "uri": "http://rightsstatements.org/vocab/UND/1.0/",
          "vocabulary_id": 15,
          "created_at": "2016-08-26 15:47:22 UTC",
          "updated_at": "2016-08-26 15:47:22 UTC"
        }
      ]
    }
    HEREDOC
    vocab = Vocabulary.from_json(json)
    assert_equal 'rs', vocab.key
    assert_equal 'RightsStatements.org', vocab.name
    assert_equal 2, vocab.vocabulary_terms.length

    term = vocab.vocabulary_terms.first
    assert_equal 'Copyright Not Evaluated', term.string
    assert_equal 'http://rightsstatements.org/vocab/CNE/1.0/', term.uri
  end

  test 'from_json should raise an error when importing JSON that contains '\
  'a key that already exists' do
    Vocabulary.create!(key: 'rs', name: 'bogus')
    json = <<-HEREDOC
    {
      "id": 15,
      "key": "rs",
      "name": "RightsStatements.org",
      "created_at": "2016-08-26 15:39:02 UTC",
      "updated_at": "2016-08-26 15:39:02 UTC",
      "vocabulary_terms": [
        {
          "id": 13,
          "string": "Copyright Not Evaluated",
          "uri": "http://rightsstatements.org/vocab/CNE/1.0/",
          "vocabulary_id": 15,
          "created_at": "2016-08-26 15:47:09 UTC",
          "updated_at": "2016-08-26 15:47:09 UTC"
        },
        {
          "id": 14,
          "string": "Copyright Undetermined",
          "uri": "http://rightsstatements.org/vocab/UND/1.0/",
          "vocabulary_id": 15,
          "created_at": "2016-08-26 15:47:22 UTC",
          "updated_at": "2016-08-26 15:47:22 UTC"
        }
      ]
    }
    HEREDOC
    assert_raises ArgumentError do
      Vocabulary.from_json(json)
    end
  end

  test 'from_json should raise an error when importing JSON that contains '\
  'a name that already exists' do
    Vocabulary.create!(key: 'bogus', name: 'RightsStatements.org')
    json = <<-HEREDOC
    {
      "id": 15,
      "key": "rs",
      "name": "RightsStatements.org",
      "created_at": "2016-08-26 15:39:02 UTC",
      "updated_at": "2016-08-26 15:39:02 UTC",
      "vocabulary_terms": [
        {
          "id": 13,
          "string": "Copyright Not Evaluated",
          "uri": "http://rightsstatements.org/vocab/CNE/1.0/",
          "vocabulary_id": 15,
          "created_at": "2016-08-26 15:47:09 UTC",
          "updated_at": "2016-08-26 15:47:09 UTC"
        },
        {
          "id": 14,
          "string": "Copyright Undetermined",
          "uri": "http://rightsstatements.org/vocab/UND/1.0/",
          "vocabulary_id": 15,
          "created_at": "2016-08-26 15:47:22 UTC",
          "updated_at": "2016-08-26 15:47:22 UTC"
        }
      ]
    }
    HEREDOC
    assert_raises ArgumentError do
      Vocabulary.from_json(json)
    end
  end

end
