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

# Roles
roles = {}
roles[:admin] = Role.create!(key: 'admin', name: 'Administrators', required: true)
roles[:cataloger] = Role.create!(key: 'cataloger', name: 'Catalogers')
roles[:anybody] = Role.create!(key: 'anybody', name: 'Anybody', required: true)

# Permissions
Permission.create!(key: Permission::Permissions::UPDATE_COLLECTION,
                   roles: [roles[:admin], roles[:cataloger]])
Permission.create!(key: Permission::Permissions::ACCESS_CONTROL_PANEL,
                   roles: [roles[:admin], roles[:cataloger]])
Permission.create!(key: Permission::Permissions::REINDEX,
                   roles: [roles[:admin], roles[:cataloger]])
Permission.create!(key: Permission::Permissions::CREATE_ROLE,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::Permissions::DELETE_ROLE,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::Permissions::UPDATE_ROLE,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::Permissions::UPDATE_SETTINGS,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::Permissions::CREATE_USER,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::Permissions::DELETE_USER,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::Permissions::UPDATE_USER,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::Permissions::UPDATE_SELF,
                   roles: [roles[:admin], roles[:anybody]])
Permission.create!(key: Permission::Permissions::DISABLE_USER,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::Permissions::ENABLE_USER,
                   roles: [roles[:admin]])

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

Solr.instance.commit
