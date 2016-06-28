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
Permission.create!(key: Permission::UPDATE_COLLECTION,
                   roles: [roles[:admin], roles[:cataloger]])
Permission.create!(key: Permission::ACCESS_CONTROL_PANEL,
                   roles: [roles[:admin], roles[:cataloger]])
Permission.create!(key: Permission::REINDEX,
                   roles: [roles[:admin], roles[:cataloger]])
Permission.create!(key: Permission::CREATE_ROLE,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::DELETE_ROLE,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::UPDATE_ROLE,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::UPDATE_SETTINGS,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::CREATE_USER,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::DELETE_USER,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::UPDATE_USER,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::UPDATE_SELF,
                   roles: [roles[:admin], roles[:anybody]])
Permission.create!(key: Permission::DISABLE_USER,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::ENABLE_USER,
                   roles: [roles[:admin]])
Permission.create!(key: Permission::VIEW_USERS,
                   roles: [roles[:admin], roles[:cataloger]])

# Metadata profiles
profiles = {}
profiles[:default] = MetadataProfile.create!(name: 'Default Profile',
                                             default: true)

# Vocabularies
Vocabulary.create!(name: 'Uncontrolled Vocabulary', key: 'uncontrolled')

# Collections

collections = {}
# https://medusa.library.illinois.edu/collections/162
collections[:sanborn] = Collection.from_medusa(
    '6ff64b00-072d-0130-c5bb-0019b9e633c5-2')
collections[:sanborn].save!

# Items

# top-level item:
# https://medusa.library.illinois.edu/cfs_directories/414021
item = Item.create!(repository_id: 'be8d3500-c451-0133-1d17-0050569601ca-9',
                    collection_repository_id: collections[:sanborn].repository_id)
item.elements.create(name: 'title', value: 'Test Item')
item.elements.create(name: 'description', value: 'Test description')

# page of the above:
# https://medusa.library.illinois.edu/cfs_files/9799019
item = Item.create!(repository_id: 'd25db810-c451-0133-1d17-0050569601ca-3',
                    collection_repository_id: collections[:sanborn].repository_id,
                    parent_repository_id: item.repository_id,
                    page_number: 1,
                    variant: Item::Variants::PAGE)
item.elements.create(name: 'title', value: 'Test Page')
item.elements.create(name: 'description', value: 'Test description')

# access master
# https://medusa.library.illinois.edu/cfs_files/9799019
bs = item.bytestreams.build
bs.repository_relative_pathname = '/162/2204/1601831/access/1601831_001.jp2'
bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
bs.infer_media_type
bs.save!

# preservation master
# https://medusa.library.illinois.edu/cfs_files/9799028
bs = item.bytestreams.build
bs.repository_relative_pathname = '/162/2204/1601831/preservation/1601831_001.tif'
bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
bs.infer_media_type
bs.save!

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
