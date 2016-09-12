require 'test_helper'

class MetadataProfileTest < ActiveSupport::TestCase

  setup do
    @profile = metadata_profiles(:default_metadata_profile)
  end

  test 'default_element_defs should work' do
    assert MetadataProfile.default_element_defs.length == 5
  end

  test 'from_json should work' do
    json = <<-HEREDOC
    {
        "id": 15,
        "name": "Test Profile",
        "default": false,
        "created_at": "2016-06-28T17:46:31.072Z",
        "updated_at": "2016-06-28T17:46:31.072Z",
        "default_sortable_element_def_id": 1366,
        "element_defs": [
            {
                "id": 1367,
                "metadata_profile_id": 15,
                "name": "accessRights",
                "label": "Access Rights",
                "index": 0,
                "searchable": true,
                "facetable": true,
                "visible": true,
                "created_at": "2016-06-28T17:46:31.197Z",
                "updated_at": "2016-06-28T17:46:31.197Z",
                "sortable": true,
                "dc_map": "rights",
                "dcterms_map": "accessRights",
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
                "id": 1368,
                "metadata_profile_id": 15,
                "name": "accrualMethod",
                "label": "Accrual Method",
                "index": 1,
                "searchable": true,
                "facetable": true,
                "visible": true,
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
            },
            {
                "id": 1366,
                "metadata_profile_id": 15,
                "name": "abstract",
                "label": "Abstract",
                "index": 2,
                "searchable": true,
                "facetable": true,
                "visible": true,
                "created_at": "2016-06-28T17:46:31.188Z",
                "updated_at": "2016-06-28T17:46:48.894Z",
                "sortable": true,
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
            },
            {
                "id": 1369,
                "metadata_profile_id": 15,
                "name": "accrualPeriodicity",
                "label": "Accrual Periodicity",
                "index": 3,
                "searchable": true,
                "facetable": true,
                "visible": true,
                "created_at": "2016-06-28T17:46:31.216Z",
                "updated_at": "2016-06-28T17:46:31.216Z",
                "sortable": true,
                "dc_map": null,
                "dcterms_map": "accrualPeriodicity",
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
    assert_equal 4, profile.element_defs.length

    abstract = profile.element_defs.select{ |ed| ed.name == 'abstract' }.first
    assert_equal abstract.id, profile.default_sortable_element_def_id
    assert_equal 'Abstract', abstract.label
    assert_equal profile.id, abstract.metadata_profile_id
    assert_equal 2, abstract.index
    assert abstract.searchable
    assert abstract.facetable
    assert abstract.visible
    assert abstract.sortable
    assert_equal 'description', abstract.dc_map
    assert_equal 'abstract', abstract.dcterms_map

    assert_equal 1, abstract.vocabularies.length
    assert_equal 'uncontrolled', abstract.vocabularies.first.key
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
        "default_sortable_element_def_id": 1366,
        "element_defs": [
            {
                "id": 1367,
                "metadata_profile_id": 15,
                "name": "accessRights",
                "label": "Access Rights",
                "index": 0,
                "searchable": true,
                "facetable": true,
                "visible": true,
                "created_at": "2016-06-28T17:46:31.197Z",
                "updated_at": "2016-06-28T17:46:31.197Z",
                "sortable": true,
                "dc_map": "rights",
                "dcterms_map": "accessRights",
                "vocabularies": [
                    {
                        "id": 11234,
                        "key": "nonexistent",
                        "name": "Nonexistent",
                        "created_at": "2016-06-28T17:36:17.824Z",
                        "updated_at": "2016-06-28T17:37:39.868Z"
                    }
                ]
            },
            {
                "id": 1368,
                "metadata_profile_id": 15,
                "name": "accrualMethod",
                "label": "Accrual Method",
                "index": 1,
                "searchable": true,
                "facetable": true,
                "visible": true,
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
            },
            {
                "id": 1366,
                "metadata_profile_id": 15,
                "name": "abstract",
                "label": "Abstract",
                "index": 2,
                "searchable": true,
                "facetable": true,
                "visible": true,
                "created_at": "2016-06-28T17:46:31.188Z",
                "updated_at": "2016-06-28T17:46:48.894Z",
                "sortable": true,
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
            },
            {
                "id": 1369,
                "metadata_profile_id": 15,
                "name": "accrualPeriodicity",
                "label": "Accrual Periodicity",
                "index": 3,
                "searchable": true,
                "facetable": true,
                "visible": true,
                "created_at": "2016-06-28T17:46:31.216Z",
                "updated_at": "2016-06-28T17:46:31.216Z",
                "sortable": true,
                "dc_map": null,
                "dcterms_map": "accrualPeriodicity",
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
    assert_raises RuntimeError do
      MetadataProfile.from_json(json)
    end
  end

  test 'add_default_element_defs should work' do
    @profile.add_default_element_defs
  end

  test 'dup should work' do
    dup = @profile.dup
    puts dup.elements.map(&:name)
    dup.save!
  end

end
