# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Options
Option.set(Option::Keys::ADMINISTRATOR_EMAIL, 'admin@example.org')
Option.set(Option::Keys::COPYRIGHT_STATEMENT,
           'Copyright © 2015 My Great Organization. All rights reserved.')
Option.set(Option::Keys::CURRENT_INDEX_VERSION,
           ElasticsearchIndex.latest_index_version)
Option.set(Option::Keys::FACET_TERM_LIMIT, 10)
Option.set(Option::Keys::OAI_PMH_ENABLED, true)
Option.set(Option::Keys::ORGANIZATION_NAME, 'My Great Organization')
Option.set(Option::Keys::WEBSITE_NAME,
               'My Great Organization Digital Collections')
Option.set(Option::Keys::DEFAULT_RESULT_WINDOW, 30)

# Roles
roles = {}
roles[:admin] = Role.create!(key: 'admin', name: 'Administrators', required: true)
roles[:cataloger] = Role.create!(key: 'cataloger', name: 'Catalogers')

# Metadata profiles
profiles = {}
profiles[:default] = MetadataProfile.create!(name: 'Default Profile',
                                             default: true)

# Elements

%w(abstract accessRights accrualMethod accrualPeriodicity accrualPolicy
alternativeTitle audience bibId bibliographicCitation callNumber
cartographicScale conformsTo contributor creator date dateAccepted
dateAvailable dateCopyrighted dateCreated dateIssued dateModified
dateSubmitted dateValid description dimensions educationLevel extent format
hasFormat hasPart hasVersion identifier instructionalMethod isFormatOf
isPartOf isReferencedBy isReplacedBy isRequiredBy isVersionOf keyword language
license localId materialsColor materialsTechniques mediator medium notes
physicalLocation provenance publicationPlace publisher references relation
replaces requires rights rightsHolder source spatialCoverage subject
tableOfContents temporalCoverage title type).each do |element|
  Element.create!(name: element)
end

# Vocabularies
Vocabulary.create!(name: 'Uncontrolled Vocabulary', key: 'uncontrolled')

# Admin user
users = {}
users[:admin] = User.create!(
    username: 'admin',
    roles: [roles[:admin]],
    enabled: true)

if Rails.env.development?
  # Non-admin users
  users[:cataloger] = User.create!(
      username: 'cataloger',
      roles: [roles[:cataloger]],
      enabled: true)
  users[:disabled] = User.create!(
      username: 'disabled',
      roles: [roles[:cataloger]],
      enabled: false)
end

# Overwrite some default options for internal demo purposes
option = Option.find_by_key(Option::Keys::COPYRIGHT_STATEMENT)
option.value = 'Copyright © 2015 The Board of Trustees at the '\
'University of Illinois. All rights reserved.'
option.save!

option = Option.find_by_key(Option::Keys::ORGANIZATION_NAME)
option.value = 'University of Illinois at Urbana-Champaign Library'
option.save!

option = Option.find_by_key(Option::Keys::WEBSITE_NAME)
option.value = 'University of Illinois at Urbana-Champaign Library Digital '\
'Image Collections'
option.save!
