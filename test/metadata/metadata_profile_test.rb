require 'test_helper'

class MetadataProfileTest < ActiveSupport::TestCase

  setup do
    @profile = metadata_profiles(:default)
    assert @profile.valid?
  end

  # default_elements()

  test 'default_elements() returns correct elements' do
    elements = MetadataProfile.default_elements
    assert_equal Element.count, elements.length

    # Check an uncontrolled element.
    elem = elements.find{ |e| e.name == "title" }
    assert_not_nil elem.name
    assert_not_nil elem.label
    assert elem.visible
    assert elem.searchable
    assert elem.sortable
    assert elem.facetable
    assert elem.indexed
    assert_equal "title", elem.dc_map
    assert_equal "title", elem.dcterms_map
    assert_equal 1, elem.vocabularies.length
    assert_equal Vocabulary.uncontrolled, elem.vocabularies.first
    assert elem.index >= 0
  end

  test 'default_elements() assigns correct vocabularies to the accessRights
  element' do
    elem = MetadataProfile.default_elements.find{ |e| e.name == EntityElement::CONTROLLED_RIGHTS_ELEMENT }
    expected_vocabs = [Vocabulary.uncontrolled,
                       Vocabulary.find_by_key("rights"),
                       Vocabulary.find_by_key("cc")]
    assert_equal elem.vocabularies.to_a, expected_vocabs
  end

  # from_json()

  test 'from_json() works' do
    json = <<-HEREDOC
    {
        "id": 15,
        "name": "Test Profile",
        "default": false,
        "created_at": "2016-06-28T17:46:31.072Z",
        "updated_at": "2016-06-28T17:46:31.072Z",
        "default_sortable_element_id": 1366,
        "elements": [
            {
                "id": 1368,
                "metadata_profile_id": 15,
                "name": "title",
                "label": "Title",
                "index": 1,
                "searchable": true,
                "facetable": true,
                "visible": true,
                "created_at": "2016-06-28T17:46:31.206Z",
                "updated_at": "2016-06-28T17:46:31.206Z",
                "sortable": true,
                "indexed": true,
                "dc_map": null,
                "dcterms_map": "accrualMethod",
                "vocabularies": [
                    {
                        "id": 11,
                        "key": "uncontrolled",
                        "name": "Uncontrolled",
                        "created_at": "2016-06-28T17:36:17.824Z",
                        "updated_at": "2016-06-28T17:37:39.868Z"
                    }
                ]
            },
            {
                "id": 1366,
                "metadata_profile_id": 15,
                "name": "subject",
                "label": "Subject",
                "index": 2,
                "searchable": true,
                "facetable": true,
                "visible": true,
                "created_at": "2016-06-28T17:46:31.188Z",
                "updated_at": "2016-06-28T17:46:48.894Z",
                "sortable": true,
                "indexed": true,
                "dc_map": "description",
                "dcterms_map": "abstract",
                "vocabularies": [
                    {
                        "id": 11,
                        "key": "uncontrolled",
                        "name": "Uncontrolled",
                        "created_at": "2016-06-28T17:36:17.824Z",
                        "updated_at": "2016-06-28T17:37:39.868Z"
                    }
                ]
            }
        ]
    }
    HEREDOC
    profile = MetadataProfile.from_json(json)
    assert_equal 'Test Profile (imported)', profile.name
    assert_equal 2, profile.elements.length

    subject = profile.elements.find{ |ed| ed.name == 'subject' }
    assert_equal subject.id, profile.default_sortable_element_id
    assert_equal 'Subject', subject.label
    assert_equal profile.id, subject.metadata_profile_id
    assert_equal 2, subject.index
    assert subject.searchable
    assert subject.facetable
    assert subject.visible
    assert subject.sortable
    assert subject.indexed
    assert_equal 'description', subject.dc_map
    assert_equal 'abstract', subject.dcterms_map

    assert_equal 1, subject.vocabularies.length
    assert_equal 'uncontrolled', subject.vocabularies.first.key
  end

  test 'from_json should raise an error when importing JSON that contains '\
  'references to elements that do not exist' do
    json = <<-HEREDOC
    {
        "id": 15,
        "name": "Test Profile",
        "default": false,
        "created_at": "2016-06-28T17:46:31.072Z",
        "updated_at": "2016-06-28T17:46:31.072Z",
        "default_sortable_element_id": 1366,
        "elements": [
            {
                "id": 1368,
                "metadata_profile_id": 15,
                "name": "accrualMethod",
                "label": "Accrual Method",
                "index": 1,
                "searchable": true,
                "facetable": true,
                "visible": true,
                "indexed": true,
                "created_at": "2016-06-28T17:46:31.206Z",
                "updated_at": "2016-06-28T17:46:31.206Z",
                "sortable": true,
                "dc_map": null,
                "dcterms_map": "accrualMethod",
                "vocabularies": [
                    {
                        "id": 11,
                        "key": "uncontrolled",
                        "name": "Uncontrolled",
                        "created_at": "2016-06-28T17:36:17.824Z",
                        "updated_at": "2016-06-28T17:37:39.868Z"
                    }
                ]
            }
        ]
    }
    HEREDOC
    assert_raises ActiveRecord::RecordInvalid do
      MetadataProfile.from_json(json)
    end
  end

  test 'from_json should raise an error when importing JSON that contains '\
  'references to vocabularies that do not exist' do
    json = <<-HEREDOC
    {
        "id": 15,
        "name": "Test Profile",
        "default": false,
        "created_at": "2016-06-28T17:46:31.072Z",
        "updated_at": "2016-06-28T17:46:31.072Z",
        "default_sortable_element_id": 1366,
        "elements": [
            {
                "id": 1368,
                "metadata_profile_id": 15,
                "name": "title",
                "label": "Title",
                "index": 1,
                "searchable": true,
                "facetable": true,
                "visible": true,
                "indexed": true,
                "created_at": "2016-06-28T17:46:31.206Z",
                "updated_at": "2016-06-28T17:46:31.206Z",
                "sortable": true,
                "dc_map": null,
                "dcterms_map": "accrualMethod",
                "vocabularies": [
                    {
                        "id": 11234,
                        "key": "nonexistent",
                        "name": "Nonexistent",
                        "created_at": "2016-06-28T17:36:17.824Z",
                        "updated_at": "2016-06-28T17:37:39.868Z"
                    }
                ]
            }
        ]
    }
    HEREDOC
    assert_raises RuntimeError do
      MetadataProfile.from_json(json)
    end
  end

  test 'add_default_elements should work' do
    @profile.add_default_elements
  end

  test 'dup should work' do
    dup = @profile.dup
    dup.save!
  end

  test 'validate() should reject profiles with non-DLS elements' do
    @profile.elements.build(name: 'bogus')
    assert !@profile.valid?
  end

end
