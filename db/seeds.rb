# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Options
Setting.set(Setting::Keys::ADMINISTRATOR_EMAIL, 'admin@example.org')
Setting.set(Setting::Keys::COPYRIGHT_STATEMENT,
            'Copyright © 2015 My Great Organization. All rights reserved.')
Setting.set(Setting::Keys::ORGANIZATION_NAME, 'My Great Organization')
Setting.set(Setting::Keys::WEBSITE_NAME,
            'My Great Organization Digital Collections')
Setting.set(Setting::Keys::DEFAULT_RESULT_WINDOW, 30)

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

# Users
if Rails.env.development?
  User.create!(username: 'admin')
  User.create!(username: 'cataloger')
end

# Overwrite some default options for internal demo purposes
setting = Setting.find_by_key(Setting::Keys::COPYRIGHT_STATEMENT)
setting.value = 'Copyright © 2015 The Board of Trustees at the '\
'University of Illinois. All rights reserved.'
setting.save!

setting = Setting.find_by_key(Setting::Keys::ORGANIZATION_NAME)
setting.value = 'University of Illinois at Urbana-Champaign Library'
setting.save!

setting = Setting.find_by_key(Setting::Keys::WEBSITE_NAME)
setting.value = 'University of Illinois at Urbana-Champaign Library Digital '\
'Image Collections'
setting.save!
