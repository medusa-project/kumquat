# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Options
Option.create!(key: Option::Key::ADMINISTRATOR_EMAIL,
               value: 'admin@example.org')
Option.create!(key: Option::Key::COPYRIGHT_STATEMENT,
               value: 'Copyright © 2015 My Great Organization. All rights reserved.')
Option.create!(key: Option::Key::FACET_TERM_LIMIT, value: 10)
Option.create!(key: Option::Key::OAI_PMH_ENABLED, value: true)
Option.create!(key: Option::Key::ORGANIZATION_NAME,
               value: 'My Great Organization')
Option.create!(key: Option::Key::WEBSITE_NAME,
               value: 'My Great Organization Digital Collections')
Option.create!(key: Option::Key::WEBSITE_INTRO_TEXT,
               value: 'Behold our great collections.')
Option.create!(key: Option::Key::RESULTS_PER_PAGE, value: 30)

# Facets
facets = {}
facets[:audience] = FacetDef.create!(
    name: 'Audience', solr_field: 'audience_facet')
facets[:collection] = FacetDef.create!(
    name: 'Collection', solr_field: 'collection_facet')
facets[:contributor] = FacetDef.create!(
    name: 'Contributor', solr_field: 'contributor_facet')
facets[:coverage] = FacetDef.create!(
    name: 'Coverage', solr_field: 'coverage_facet')
facets[:creator] = FacetDef.create!(
    name: 'Creator', solr_field: 'creator_facet')
facets[:date] = FacetDef.create!(
    name: 'Date', solr_field: 'date_facet')
facets[:educationLevel] = FacetDef.create!(
    name: 'Education Level', solr_field: 'education_level_facet')
facets[:format] = FacetDef.create!(
    name: 'Format', solr_field: 'format_facet')
facets[:language] = FacetDef.create!(
    name: 'Language', solr_field: 'language_facet')
facets[:publisher] = FacetDef.create!(
    name: 'Publisher', solr_field: 'publisher_facet')
facets[:source] = FacetDef.create!(
    name: 'Source', solr_field: 'source_facet')
facets[:subject] = FacetDef.create!(
    name: 'Subject', solr_field: 'subject_facet')
facets[:type] = FacetDef.create!(
    name: 'Type', solr_field: 'type_facet')

# Metadata profiles
profiles = {}
profiles[:default] = MetadataProfile.create!(name: 'Default Profile',
                                             default: true)

ElementDef.create!(
    name: 'abstract',
    label: 'Abstract',
    visible: true,
    searchable: true,
    index: 0,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'accessRights',
    label: 'Access Rights',
    visible: true,
    searchable: true,
    index: 1,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'accrualMethod',
    label: 'Accrual Method',
    visible: true,
    searchable: true,
    index: 2,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'accrualPeriodicity',
    label: 'Accrual Periodicity',
    visible: true,
    searchable: true,
    index: 3,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'accrualPolicy',
    label: 'Accrual Policy',
    visible: true,
    searchable: true,
    index: 4,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'alternativeTitle',
    label: 'Alternative Title',
    visible: true,
    searchable: true,
    index: 5,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'audience',
    label: 'Audience',
    visible: true,
    searchable: true,
    index: 6,
    facet_def: facets[:audience],
    facet_def_label: 'Audience',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'bibliographicCitation',
    label: 'Bibliographic Citation',
    visible: true,
    searchable: true,
    index: 7,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'cartographicScale',
    label: 'Cartographic Scale',
    visible: true,
    searchable: true,
    index: 8,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'conformsTo',
    label: 'Conforms To',
    visible: true,
    searchable: true,
    index: 9,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'contributor',
    label: 'Contributor',
    visible: true,
    searchable: true,
    index: 10,
    facet_def: facets[:contributor],
    facet_def_label: 'Contributor',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'coverage',
    label: 'Coverage',
    visible: true,
    searchable: true,
    index: 11,
    facet_def: facets[:coverage],
    facet_def_label: 'Coverage',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'creator',
    label: 'Creator',
    visible: true,
    searchable: true,
    index: 12,
    facet_def: facets[:creator],
    facet_def_label: 'Creator',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'date',
    label: 'Date',
    visible: true,
    searchable: true,
    index: 13,
    facet_def: facets[:date],
    facet_def_label: 'Date',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'dateAccepted',
    label: 'Date Accepted',
    visible: true,
    searchable: true,
    index: 14,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'dateAvailable',
    label: 'Date Available',
    visible: true,
    searchable: true,
    index: 15,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'dateCopyrighted',
    label: 'Date Copyrighted',
    visible: true,
    searchable: true,
    index: 16,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'dateCreated',
    label: 'Date Created',
    visible: true,
    searchable: true,
    index: 17,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'dateIssued',
    label: 'Date Issued',
    visible: true,
    searchable: true,
    index: 18,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'dateModified',
    label: 'Date Modified',
    visible: true,
    searchable: true,
    index: 19,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'dateSubmitted',
    label: 'Date Submitted',
    visible: true,
    searchable: true,
    index: 20,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'dateValid',
    label: 'Date Valid',
    visible: true,
    searchable: true,
    index: 21,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'description',
    label: 'Description',
    visible: true,
    searchable: true,
    index: 22,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'dimensions',
    label: 'Dimensions',
    visible: true,
    searchable: true,
    index: 23,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'educationLevel',
    label: 'Education Level',
    visible: true,
    searchable: true,
    index: 24,
    facet_def: facets[:educationLevel],
    facet_def_label: 'Education Level',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'extent',
    label: 'Extent',
    visible: true,
    searchable: true,
    index: 25,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'format',
    label: 'Format',
    visible: true,
    searchable: true,
    index: 26,
    facet_def: facets[:format],
    facet_def_label: 'Format',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'hasFormat',
    label: 'Has Format',
    visible: true,
    searchable: true,
    index: 27,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'hasPart',
    label: 'Has Part',
    visible: true,
    searchable: true,
    index: 28,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'hasVersion',
    label: 'Has Version',
    visible: true,
    searchable: true,
    index: 29,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'identifier',
    label: 'Identifier',
    visible: true,
    searchable: true,
    index: 30,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'instructionalMethod',
    label: 'Instructional Method',
    visible: true,
    searchable: true,
    index: 31,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'isFormatOf',
    label: 'Is Format Of',
    visible: true,
    searchable: true,
    index: 32,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'isPartOf',
    label: 'Is Part Of',
    visible: true,
    searchable: true,
    index: 33,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'isReferencedBy',
    label: 'Is Referenced By',
    visible: true,
    searchable: true,
    index: 34,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'isReplacedBy',
    label: 'Is Replaced By',
    visible: true,
    searchable: true,
    index: 35,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'isRequiredBy',
    label: 'Is Required By',
    visible: true,
    searchable: true,
    index: 36,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'isVersionOf',
    label: 'Is Version Of',
    visible: true,
    searchable: true,
    index: 37,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'language',
    label: 'Language',
    visible: true,
    searchable: true,
    index: 38,
    facet_def: facets[:language],
    facet_def_label: 'Language',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'latitude',
    label: 'Latitude',
    visible: true,
    searchable: true,
    index: 39,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'license',
    label: 'License',
    visible: true,
    searchable: true,
    index: 40,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'longitude',
    label: 'Longitude',
    visible: true,
    searchable: true,
    index: 41,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'mediator',
    label: 'Mediator',
    visible: true,
    searchable: true,
    index: 42,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'medium',
    label: 'Medium',
    visible: true,
    searchable: true,
    index: 43,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'notes',
    label: 'Notes',
    visible: true,
    searchable: true,
    index: 44,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'physicalLocation',
    label: 'Physical Location',
    visible: true,
    searchable: true,
    index: 45,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'provenance',
    label: 'Provenance',
    visible: true,
    searchable: true,
    index: 46,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'publicationPlace',
    label: 'Publication Place',
    visible: true,
    searchable: true,
    index: 47,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'publisher',
    label: 'Publisher',
    visible: true,
    searchable: true,
    index: 48,
    facet_def: facets[:publisher],
    facet_def_label: 'Publisher',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'references',
    label: 'References',
    visible: true,
    searchable: true,
    index: 49,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'relation',
    label: 'Relation',
    visible: true,
    searchable: true,
    index: 50,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'replaces',
    label: 'Replaces',
    visible: true,
    searchable: true,
    index: 51,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'requires',
    label: 'Requires',
    visible: true,
    searchable: true,
    index: 52,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'rights',
    label: 'Rights',
    visible: true,
    searchable: true,
    index: 53,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'rightsHolder',
    label: 'Rights Holder',
    visible: true,
    searchable: true,
    index: 54,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'source',
    label: 'Source',
    visible: true,
    searchable: true,
    index: 55,
    facet_def: facets[:source],
    facet_def_label: 'Source',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'spatialCoverage',
    label: 'Spatial Coverage',
    visible: true,
    searchable: true,
    index: 56,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'subject',
    label: 'Subject',
    visible: true,
    searchable: true,
    index: 57,
    facet_def: facets[:subject],
    facet_def_label: 'Subject',
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'tableOfContents',
    label: 'Table Of Contents',
    visible: true,
    searchable: true,
    index: 58,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'temporalCoverage',
    label: 'Temporal Coverage',
    visible: true,
    searchable: true,
    index: 59,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'title',
    label: 'Title',
    visible: true,
    searchable: true,
    index: 60,
    metadata_profile: profiles[:default])
ElementDef.create!(
    name: 'type',
    label: 'Type',
    visible: true,
    searchable: true,
    index: 61,
    facet_def: facets[:type],
    facet_def_label: 'Type',
    metadata_profile: profiles[:default])

# Admin user
users = {}
users[:admin] = User.create!(
    email: 'admin@example.org',
    username: 'admin',
    password: 'kumquats4ever',
    enabled: true)

if Rails.env.development? or Rails.env.uiuc_development?
  # Non-admin users
  users[:cataloger] = User.create!(
      email: 'cataloger@example.org',
      username: 'cataloger',
      password: 'password',
      enabled: true)
  users[:disabled] = User.create!(
      email: 'disabled@example.org',
      password: 'password',
      username: 'disabled',
      enabled: false)
end

if Rails.env.start_with?('uiuc')

  # Themes
  Theme.create!(name: 'UIUC', default: true)

  # Overwrite some default options for internal demo purposes
  option = Option.find_by_key(Option::Key::COPYRIGHT_STATEMENT)
  option.value = 'Copyright © 2015 The Board of Trustees at the '\
  'University of Illinois. All rights reserved.'
  option.save!

  option = Option.find_by_key(Option::Key::ORGANIZATION_NAME)
  option.value = 'University of Illinois at Urbana-Champaign Library'
  option.save!

  option = Option.find_by_key(Option::Key::WEBSITE_NAME)
  option.value = 'University of Illinois at Urbana-Champaign Library Digital '\
  'Image Collections'
  option.save!

  option = Option.find_by_key(Option::Key::WEBSITE_INTRO_TEXT)
  option.value = "The digital collections of the Library of the University of "\
  "Illinois at Urbana-Champaign are built from the rich special collections "\
  "of its Rare Book & Manuscript Library; Illinois History and Lincoln "\
  "Collection, University Archives; Map Library; and Sousa Archives & Center "\
  "for American Music, among other units.\n\n"\
  "The collections include historic photographs; maps; prints and "\
  "watercolors; bookplates; architectural drawings and blueprints; letters "\
  "and other archival materials; videos; political cartoons; and "\
  "advertisements. They cover a wide range of subject areas including "\
  "Illinois and American history, music, theater history, and the history of "\
  "the University of Illinois, among others. The Library’s digital "\
  "collections provide access to some of its most unique holdings for "\
  "teaching, learning, and research for students, scholars and the general "\
  "public.\n\n"\
  "The Library contributes collaboratively to local, national, and "\
  "international digital initiatives, such as the Digital Public Library of "\
  "America and the Biodiversity Heritage Library."
  option.save!

end
