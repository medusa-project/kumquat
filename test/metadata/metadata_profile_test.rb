require 'test_helper'

class MetadataProfileTest < ActiveSupport::TestCase

  test 'default_element_defs should work' do
    assert MetadataProfile.default_element_defs.length == 5
  end

  test 'from_json should work' do
    json = <<-HEREDOC
    {
      "id": 1,
      "name": "Test Profile",
      "default": true,
      "created_at": "2016-05-25T14:14:24.428Z",
      "updated_at": "2016-05-25T14:14:24.428Z",
      "default_sortable_element_def_id": 1,
      "element_defs": [
        {
          "id": 1,
          "metadata_profile_id": 1,
          "name": "abstract",
          "label": "AbstractTest",
          "index": 0,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.454Z",
          "updated_at": "2016-05-25T14:14:24.454Z",
          "sortable": true,
          "dc_map": "description",
          "dcterms_map": "abstract"
        },
        {
          "id": 2,
          "metadata_profile_id": 1,
          "name": "accessRights",
          "label": "Access Rights",
          "index": 1,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.460Z",
          "updated_at": "2016-05-25T14:14:24.460Z",
          "sortable": true,
          "dc_map": "rights",
          "dcterms_map": "accessRights"
        },
        {
          "id": 3,
          "metadata_profile_id": 1,
          "name": "accrualMethod",
          "label": "Accrual Method",
          "index": 2,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.467Z",
          "updated_at": "2016-05-25T14:14:24.467Z",
          "sortable": true,
          "dc_map": null,
          "dcterms_map": "accrualMethod"
        },
        {
          "id": 4,
          "metadata_profile_id": 1,
          "name": "accrualPeriodicity",
          "label": "Accrual Periodicity",
          "index": 3,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.471Z",
          "updated_at": "2016-05-25T14:14:24.471Z",
          "sortable": true,
          "dc_map": null,
          "dcterms_map": "accrualPeriodicity"
        },
        {
          "id": 5,
          "metadata_profile_id": 1,
          "name": "accrualPolicy",
          "label": "Accural Policy",
          "index": 4,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.476Z",
          "updated_at": "2016-05-25T14:14:24.476Z",
          "sortable": true,
          "dc_map": null,
          "dcterms_map": "accrualPolicy"
        },
        {
          "id": 6,
          "metadata_profile_id": 1,
          "name": "alternativeTitle",
          "label": "Alternative Title",
          "index": 5,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.480Z",
          "updated_at": "2016-05-25T14:14:24.480Z",
          "sortable": true,
          "dc_map": "title",
          "dcterms_map": "alternative"
        },
        {
          "id": 7,
          "metadata_profile_id": 1,
          "name": "audience",
          "label": "Audience",
          "index": 6,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.485Z",
          "updated_at": "2016-05-25T14:14:24.485Z",
          "sortable": true,
          "dc_map": null,
          "dcterms_map": "audience"
        },
        {
          "id": 8,
          "metadata_profile_id": 1,
          "name": "bibId",
          "label": "Bibliographic ID",
          "index": 7,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.491Z",
          "updated_at": "2016-05-25T14:14:24.491Z",
          "sortable": true,
          "dc_map": "identifier",
          "dcterms_map": "identifier"
        },
        {
          "id": 9,
          "metadata_profile_id": 1,
          "name": "bibliographicCitation",
          "label": "Bibliographic Citation",
          "index": 8,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.498Z",
          "updated_at": "2016-05-25T14:14:24.498Z",
          "sortable": true,
          "dc_map": "identifier",
          "dcterms_map": "bibliographicCitation"
        },
        {
          "id": 10,
          "metadata_profile_id": 1,
          "name": "callNumber",
          "label": "Call Number",
          "index": 9,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.505Z",
          "updated_at": "2016-06-17T15:26:38.786Z",
          "sortable": true,
          "dc_map": "",
          "dcterms_map": ""
        },
        {
          "id": 11,
          "metadata_profile_id": 1,
          "name": "cartographicScale",
          "label": "Cartographic Scale",
          "index": 10,
          "searchable": false,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.513Z",
          "updated_at": "2016-06-17T15:23:45.355Z",
          "sortable": false,
          "dc_map": "",
          "dcterms_map": ""
        },
        {
          "id": 12,
          "metadata_profile_id": 1,
          "name": "conformsTo",
          "label": "Conforms To",
          "index": 11,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.520Z",
          "updated_at": "2016-05-25T14:14:24.520Z",
          "sortable": true,
          "dc_map": "relation",
          "dcterms_map": "conformsTo"
        },
        {
          "id": 13,
          "metadata_profile_id": 1,
          "name": "contributor",
          "label": "Contributor",
          "index": 12,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.529Z",
          "updated_at": "2016-05-25T14:14:24.529Z",
          "sortable": true,
          "dc_map": "contributor",
          "dcterms_map": "contributor"
        },
        {
          "id": 14,
          "metadata_profile_id": 1,
          "name": "creator",
          "label": "Creator",
          "index": 13,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.539Z",
          "updated_at": "2016-05-25T14:14:24.539Z",
          "sortable": true,
          "dc_map": "creator",
          "dcterms_map": "creator"
        },
        {
          "id": 15,
          "metadata_profile_id": 1,
          "name": "date",
          "label": "Date",
          "index": 14,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.548Z",
          "updated_at": "2016-06-17T15:23:55.855Z",
          "sortable": true,
          "dc_map": "date",
          "dcterms_map": "date"
        },
        {
          "id": 16,
          "metadata_profile_id": 1,
          "name": "dateAccepted",
          "label": "Date Accepted",
          "index": 15,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.557Z",
          "updated_at": "2016-05-25T14:14:24.557Z",
          "sortable": true,
          "dc_map": "date",
          "dcterms_map": "dateAccepted"
        },
        {
          "id": 17,
          "metadata_profile_id": 1,
          "name": "dateAvailable",
          "label": "Date Available",
          "index": 16,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.567Z",
          "updated_at": "2016-05-25T14:14:24.567Z",
          "sortable": true,
          "dc_map": "date",
          "dcterms_map": "available"
        },
        {
          "id": 18,
          "metadata_profile_id": 1,
          "name": "dateCopyrighted",
          "label": "Date Copyrighted",
          "index": 17,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.578Z",
          "updated_at": "2016-05-25T14:14:24.578Z",
          "sortable": true,
          "dc_map": "date",
          "dcterms_map": "dateCopyrighted"
        },
        {
          "id": 19,
          "metadata_profile_id": 1,
          "name": "dateCreated",
          "label": "Date Created",
          "index": 18,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.589Z",
          "updated_at": "2016-05-25T14:14:24.589Z",
          "sortable": true,
          "dc_map": "date",
          "dcterms_map": "created"
        },
        {
          "id": 20,
          "metadata_profile_id": 1,
          "name": "dateIssued",
          "label": "Date Issued",
          "index": 19,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.600Z",
          "updated_at": "2016-05-25T14:14:24.600Z",
          "sortable": true,
          "dc_map": "date",
          "dcterms_map": "issued"
        },
        {
          "id": 21,
          "metadata_profile_id": 1,
          "name": "dateModified",
          "label": "Date Modified",
          "index": 20,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.612Z",
          "updated_at": "2016-05-25T14:14:24.612Z",
          "sortable": true,
          "dc_map": "date",
          "dcterms_map": "modified"
        },
        {
          "id": 22,
          "metadata_profile_id": 1,
          "name": "dateSubmitted",
          "label": "Date Submitted",
          "index": 21,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.633Z",
          "updated_at": "2016-05-25T14:14:24.633Z",
          "sortable": true,
          "dc_map": "date",
          "dcterms_map": "dateSubmitted"
        },
        {
          "id": 23,
          "metadata_profile_id": 1,
          "name": "dateValid",
          "label": "Date Valid",
          "index": 22,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.648Z",
          "updated_at": "2016-05-25T14:14:24.648Z",
          "sortable": true,
          "dc_map": "date",
          "dcterms_map": "valid"
        },
        {
          "id": 24,
          "metadata_profile_id": 1,
          "name": "description",
          "label": "Description",
          "index": 23,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.662Z",
          "updated_at": "2016-05-25T14:14:24.662Z",
          "sortable": true,
          "dc_map": "description",
          "dcterms_map": "description"
        },
        {
          "id": 25,
          "metadata_profile_id": 1,
          "name": "dimensions",
          "label": "Dimensions",
          "index": 24,
          "searchable": false,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.678Z",
          "updated_at": "2016-06-17T15:24:05.836Z",
          "sortable": false,
          "dc_map": "",
          "dcterms_map": ""
        },
        {
          "id": 26,
          "metadata_profile_id": 1,
          "name": "educationLevel",
          "label": "Education Level",
          "index": 25,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.692Z",
          "updated_at": "2016-05-25T14:14:24.692Z",
          "sortable": true,
          "dc_map": null,
          "dcterms_map": "educationLevel"
        },
        {
          "id": 27,
          "metadata_profile_id": 1,
          "name": "extent",
          "label": "Extent",
          "index": 26,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.707Z",
          "updated_at": "2016-05-25T14:14:24.707Z",
          "sortable": true,
          "dc_map": "format",
          "dcterms_map": "extent"
        },
        {
          "id": 28,
          "metadata_profile_id": 1,
          "name": "format",
          "label": "Format",
          "index": 27,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.724Z",
          "updated_at": "2016-05-25T14:14:24.724Z",
          "sortable": true,
          "dc_map": "format",
          "dcterms_map": "format"
        },
        {
          "id": 29,
          "metadata_profile_id": 1,
          "name": "hasFormat",
          "label": "Has Format",
          "index": 28,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.739Z",
          "updated_at": "2016-05-25T14:14:24.739Z",
          "sortable": true,
          "dc_map": "relation",
          "dcterms_map": "hasFormat"
        },
        {
          "id": 30,
          "metadata_profile_id": 1,
          "name": "hasPart",
          "label": "Has Part",
          "index": 29,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.758Z",
          "updated_at": "2016-06-17T15:26:26.290Z",
          "sortable": false,
          "dc_map": "relation",
          "dcterms_map": ""
        },
        {
          "id": 31,
          "metadata_profile_id": 1,
          "name": "hasVersion",
          "label": "Has Part",
          "index": 30,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.777Z",
          "updated_at": "2016-05-25T14:14:24.777Z",
          "sortable": true,
          "dc_map": "relation",
          "dcterms_map": "hasVersion"
        },
        {
          "id": 32,
          "metadata_profile_id": 1,
          "name": "identifier",
          "label": "Identifier",
          "index": 31,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.795Z",
          "updated_at": "2016-05-25T14:14:24.795Z",
          "sortable": true,
          "dc_map": "identifier",
          "dcterms_map": "identifier"
        },
        {
          "id": 33,
          "metadata_profile_id": 1,
          "name": "instructionalMethod",
          "label": "Instructional Method",
          "index": 32,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.813Z",
          "updated_at": "2016-05-25T14:14:24.813Z",
          "sortable": true,
          "dc_map": null,
          "dcterms_map": "instructionalMethod"
        },
        {
          "id": 34,
          "metadata_profile_id": 1,
          "name": "isFormatOf",
          "label": "Is Format Of",
          "index": 33,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.832Z",
          "updated_at": "2016-06-17T15:24:25.710Z",
          "sortable": false,
          "dc_map": "relation",
          "dcterms_map": "isFormatOf"
        },
        {
          "id": 35,
          "metadata_profile_id": 1,
          "name": "isPartOf",
          "label": "Is Part Of",
          "index": 34,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.856Z",
          "updated_at": "2016-06-17T15:24:20.683Z",
          "sortable": false,
          "dc_map": "relation",
          "dcterms_map": "isPartOf"
        },
        {
          "id": 36,
          "metadata_profile_id": 1,
          "name": "isReferencedBy",
          "label": "Is Referenced By",
          "index": 35,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.876Z",
          "updated_at": "2016-05-25T14:14:24.876Z",
          "sortable": true,
          "dc_map": "relation",
          "dcterms_map": "isReferencedBy"
        },
        {
          "id": 37,
          "metadata_profile_id": 1,
          "name": "isReplacedBy",
          "label": "Is Replaced By",
          "index": 36,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.897Z",
          "updated_at": "2016-05-25T14:14:24.897Z",
          "sortable": true,
          "dc_map": "relation",
          "dcterms_map": "isReplacedBy"
        },
        {
          "id": 38,
          "metadata_profile_id": 1,
          "name": "isRequiredBy",
          "label": "Is Required By",
          "index": 37,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.920Z",
          "updated_at": "2016-05-25T14:14:24.920Z",
          "sortable": true,
          "dc_map": "relation",
          "dcterms_map": "isRequiredBy"
        },
        {
          "id": 39,
          "metadata_profile_id": 1,
          "name": "isVersionOf",
          "label": "Is Version Of",
          "index": 38,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.941Z",
          "updated_at": "2016-05-25T14:14:24.941Z",
          "sortable": true,
          "dc_map": "relation",
          "dcterms_map": "isVersionOf"
        },
        {
          "id": 40,
          "metadata_profile_id": 1,
          "name": "keyword",
          "label": "Keyword",
          "index": 39,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.963Z",
          "updated_at": "2016-05-25T14:14:24.963Z",
          "sortable": true,
          "dc_map": "subject",
          "dcterms_map": "subject"
        },
        {
          "id": 41,
          "metadata_profile_id": 1,
          "name": "language",
          "label": "Language",
          "index": 40,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:24.987Z",
          "updated_at": "2016-05-25T14:14:24.987Z",
          "sortable": true,
          "dc_map": "language",
          "dcterms_map": "language"
        },
        {
          "id": 42,
          "metadata_profile_id": 1,
          "name": "latitude",
          "label": "Latitude",
          "index": 41,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.010Z",
          "updated_at": "2016-05-25T14:14:25.010Z",
          "sortable": true,
          "dc_map": "coverage",
          "dcterms_map": "spatial"
        },
        {
          "id": 43,
          "metadata_profile_id": 1,
          "name": "license",
          "label": "License",
          "index": 42,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.033Z",
          "updated_at": "2016-05-25T14:14:25.033Z",
          "sortable": true,
          "dc_map": "rights",
          "dcterms_map": "license"
        },
        {
          "id": 44,
          "metadata_profile_id": 1,
          "name": "localId",
          "label": "Local ID",
          "index": 43,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.059Z",
          "updated_at": "2016-06-17T15:24:42.450Z",
          "sortable": false,
          "dc_map": "",
          "dcterms_map": ""
        },
        {
          "id": 45,
          "metadata_profile_id": 1,
          "name": "longitude",
          "label": "Longitude",
          "index": 44,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.082Z",
          "updated_at": "2016-05-25T14:14:25.082Z",
          "sortable": true,
          "dc_map": "coverage",
          "dcterms_map": "spatial"
        },
        {
          "id": 46,
          "metadata_profile_id": 1,
          "name": "materialsColor",
          "label": "Materials Color",
          "index": 45,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.106Z",
          "updated_at": "2016-05-25T14:14:25.106Z",
          "sortable": true,
          "dc_map": "description",
          "dcterms_map": "description"
        },
        {
          "id": 47,
          "metadata_profile_id": 1,
          "name": "materialsTechniques",
          "label": "Materials Techniques",
          "index": 46,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.130Z",
          "updated_at": "2016-05-25T14:14:25.130Z",
          "sortable": true,
          "dc_map": "description",
          "dcterms_map": "description"
        },
        {
          "id": 48,
          "metadata_profile_id": 1,
          "name": "mediator",
          "label": "Mediator",
          "index": 47,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.155Z",
          "updated_at": "2016-05-25T14:14:25.155Z",
          "sortable": true,
          "dc_map": null,
          "dcterms_map": "mediator"
        },
        {
          "id": 49,
          "metadata_profile_id": 1,
          "name": "medium",
          "label": "Medium",
          "index": 48,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.181Z",
          "updated_at": "2016-05-25T14:14:25.181Z",
          "sortable": true,
          "dc_map": "format",
          "dcterms_map": "medium"
        },
        {
          "id": 50,
          "metadata_profile_id": 1,
          "name": "notes",
          "label": "Notes",
          "index": 49,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.206Z",
          "updated_at": "2016-06-17T15:26:06.674Z",
          "sortable": false,
          "dc_map": "description",
          "dcterms_map": "description"
        },
        {
          "id": 51,
          "metadata_profile_id": 1,
          "name": "physicalLocation",
          "label": "Physical Location",
          "index": 50,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.240Z",
          "updated_at": "2016-06-17T15:25:50.180Z",
          "sortable": false,
          "dc_map": "",
          "dcterms_map": ""
        },
        {
          "id": 52,
          "metadata_profile_id": 1,
          "name": "provenance",
          "label": "Provenance",
          "index": 51,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.270Z",
          "updated_at": "2016-05-25T14:14:25.270Z",
          "sortable": true,
          "dc_map": null,
          "dcterms_map": "provenance"
        },
        {
          "id": 53,
          "metadata_profile_id": 1,
          "name": "publicationPlace",
          "label": "Publication Place",
          "index": 52,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.300Z",
          "updated_at": "2016-05-25T14:14:25.300Z",
          "sortable": true,
          "dc_map": null,
          "dcterms_map": null
        },
        {
          "id": 54,
          "metadata_profile_id": 1,
          "name": "publisher",
          "label": "Publisher",
          "index": 53,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.329Z",
          "updated_at": "2016-05-25T14:14:25.329Z",
          "sortable": true,
          "dc_map": "publisher",
          "dcterms_map": "publisher"
        },
        {
          "id": 55,
          "metadata_profile_id": 1,
          "name": "references",
          "label": "References",
          "index": 54,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.358Z",
          "updated_at": "2016-06-17T15:25:03.427Z",
          "sortable": false,
          "dc_map": "relation",
          "dcterms_map": "references"
        },
        {
          "id": 56,
          "metadata_profile_id": 1,
          "name": "relation",
          "label": "Relation",
          "index": 55,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.388Z",
          "updated_at": "2016-05-25T14:14:25.388Z",
          "sortable": true,
          "dc_map": "relation",
          "dcterms_map": "relation"
        },
        {
          "id": 57,
          "metadata_profile_id": 1,
          "name": "replaces",
          "label": "Replaces",
          "index": 56,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.418Z",
          "updated_at": "2016-05-25T14:14:25.418Z",
          "sortable": true,
          "dc_map": "relation",
          "dcterms_map": "replaces"
        },
        {
          "id": 58,
          "metadata_profile_id": 1,
          "name": "requires",
          "label": "Requires",
          "index": 57,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.449Z",
          "updated_at": "2016-05-25T14:14:25.449Z",
          "sortable": true,
          "dc_map": "relation",
          "dcterms_map": "requires"
        },
        {
          "id": 59,
          "metadata_profile_id": 1,
          "name": "rights",
          "label": "Rights",
          "index": 58,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.481Z",
          "updated_at": "2016-06-17T15:25:10.833Z",
          "sortable": true,
          "dc_map": "rights",
          "dcterms_map": "rights"
        },
        {
          "id": 60,
          "metadata_profile_id": 1,
          "name": "rightsHolder",
          "label": "Rights Holder",
          "index": 59,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.514Z",
          "updated_at": "2016-05-25T14:14:25.514Z",
          "sortable": true,
          "dc_map": null,
          "dcterms_map": "rightsHolder"
        },
        {
          "id": 61,
          "metadata_profile_id": 1,
          "name": "source",
          "label": "Source",
          "index": 60,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.547Z",
          "updated_at": "2016-06-17T15:25:42.332Z",
          "sortable": false,
          "dc_map": "source",
          "dcterms_map": "source"
        },
        {
          "id": 62,
          "metadata_profile_id": 1,
          "name": "spatialCoverage",
          "label": "Spatial Coverage",
          "index": 61,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.580Z",
          "updated_at": "2016-05-25T14:14:25.580Z",
          "sortable": true,
          "dc_map": "coverage",
          "dcterms_map": "spatial"
        },
        {
          "id": 63,
          "metadata_profile_id": 1,
          "name": "subject",
          "label": "Subject",
          "index": 62,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.614Z",
          "updated_at": "2016-05-25T14:14:25.614Z",
          "sortable": true,
          "dc_map": "subject",
          "dcterms_map": "subject"
        },
        {
          "id": 64,
          "metadata_profile_id": 1,
          "name": "tableOfContents",
          "label": "Table of Contents",
          "index": 63,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.650Z",
          "updated_at": "2016-05-25T14:14:25.650Z",
          "sortable": true,
          "dc_map": "description",
          "dcterms_map": "tableOfContents"
        },
        {
          "id": 65,
          "metadata_profile_id": 1,
          "name": "temporalCoverage",
          "label": "Temporal Coverage",
          "index": 64,
          "searchable": true,
          "facetable": true,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.684Z",
          "updated_at": "2016-05-25T14:14:25.684Z",
          "sortable": true,
          "dc_map": "coverage",
          "dcterms_map": "temporal"
        },
        {
          "id": 66,
          "metadata_profile_id": 1,
          "name": "title",
          "label": "Title",
          "index": 65,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.718Z",
          "updated_at": "2016-05-25T14:14:25.718Z",
          "sortable": true,
          "dc_map": "title",
          "dcterms_map": "title"
        },
        {
          "id": 67,
          "metadata_profile_id": 1,
          "name": "type",
          "label": "Type",
          "index": 66,
          "searchable": true,
          "facetable": false,
          "visible": true,
          "created_at": "2016-05-25T14:14:25.754Z",
          "updated_at": "2016-06-17T15:25:25.370Z",
          "sortable": false,
          "dc_map": "type",
          "dcterms_map": "type"
        }
      ]
    }
    HEREDOC
    profile = MetadataProfile.from_json(json)
    assert_equal 'Test Profile (imported)', profile.name
    assert_equal 67, profile.element_defs.length

    abstract = profile.element_defs.select{ |ed| ed.name == 'abstract' }.first
    assert_equal abstract.id, profile.default_sortable_element_def_id
    assert_equal 'AbstractTest', abstract.label
    assert_equal profile.id, abstract.metadata_profile_id
    assert_equal 0, abstract.index
    assert abstract.searchable
    assert abstract.facetable
    assert abstract.visible
    assert abstract.sortable
    assert_equal 'description', abstract.dc_map
    assert_equal 'abstract', abstract.dcterms_map
  end

end
