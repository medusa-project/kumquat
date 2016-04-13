class MetadataProfile < ActiveRecord::Base

  belongs_to :default_sortable_element_def, class_name: 'ElementDef'
  has_many :collections, inverse_of: :metadata_profile,
           dependent: :restrict_with_error
  has_many :element_defs, -> { order(:index) }, inverse_of: :metadata_profile,
           dependent: :destroy

  validates :name, presence: true, length: { minimum: 2 },
            uniqueness: { case_sensitive: false }

  after_create :add_default_element_defs
  after_save :ensure_default_uniqueness

  def self.default
    MetadataProfile.find_by_default(true)
  end

  def self.default_element_defs
    defs = []
    defs << ElementDef.new(
        name: 'abstract',
        label: 'Abstract',
        visible: true,
        searchable: true,
        index: 0)
    defs << ElementDef.new(
        name: 'accessRights',
        label: 'Access Rights',
        visible: true,
        searchable: true,
        index: 1)
    defs << ElementDef.new(
        name: 'accrualMethod',
        label: 'Accrual Method',
        visible: true,
        searchable: true,
        index: 2)
    defs << ElementDef.new(
        name: 'accrualPeriodicity',
        label: 'Accrual Periodicity',
        visible: true,
        searchable: true,
        index: 3)
    defs << ElementDef.new(
        name: 'accrualPolicy',
        label: 'Accrual Policy',
        visible: true,
        searchable: true,
        index: 4)
    defs << ElementDef.new(
        name: 'alternativeTitle',
        label: 'Alternative Title',
        visible: true,
        searchable: true,
        index: 5)
    defs << ElementDef.new(
        name: 'audience',
        label: 'Audience',
        visible: true,
        searchable: true,
        index: 6,
        facetable: true)
    defs << ElementDef.new(
        name: 'bibliographicCitation',
        label: 'Bibliographic Citation',
        visible: true,
        searchable: true,
        index: 7)
    defs << ElementDef.new(
        name: 'cartographicScale',
        label: 'Cartographic Scale',
        visible: true,
        searchable: true,
        index: 8)
    defs << ElementDef.new(
        name: 'conformsTo',
        label: 'Conforms To',
        visible: true,
        searchable: true,
        index: 9)
    defs << ElementDef.new(
        name: 'contributor',
        label: 'Contributor',
        visible: true,
        searchable: true,
        index: 10,
        facetable: true)
    defs << ElementDef.new(
        name: 'creator',
        label: 'Creator',
        visible: true,
        searchable: true,
        index: 11,
        sortable: true,
        facetable: true)
    defs << ElementDef.new(
        name: 'date',
        label: 'Date',
        visible: true,
        searchable: true,
        sortable: true,
        index: 12,
        facetable: true)
    defs << ElementDef.new(
        name: 'dateAccepted',
        label: 'Date Accepted',
        visible: true,
        searchable: true,
        sortable: true,
        index: 13)
    defs << ElementDef.new(
        name: 'dateAvailable',
        label: 'Date Available',
        visible: true,
        searchable: true,
        sortable: true,
        index: 14)
    defs << ElementDef.new(
        name: 'dateCopyrighted',
        label: 'Date Copyrighted',
        visible: true,
        searchable: true,
        sortable: true,
        index: 15)
    defs << ElementDef.new(
        name: 'dateCreated',
        label: 'Date Created',
        visible: true,
        searchable: true,
        sortable: true,
        index: 16)
    defs << ElementDef.new(
        name: 'dateIssued',
        label: 'Date Issued',
        visible: true,
        searchable: true,
        sortable: true,
        index: 17)
    defs << ElementDef.new(
        name: 'dateModified',
        label: 'Date Modified',
        visible: true,
        searchable: true,
        sortable: true,
        index: 18)
    defs << ElementDef.new(
        name: 'dateSubmitted',
        label: 'Date Submitted',
        visible: true,
        searchable: true,
        sortable: true,
        index: 19)
    defs << ElementDef.new(
        name: 'dateValid',
        label: 'Date Valid',
        visible: true,
        searchable: true,
        sortable: true,
        index: 20)
    defs << ElementDef.new(
        name: 'description',
        label: 'Description',
        visible: true,
        searchable: true,
        index: 21)
    defs << ElementDef.new(
        name: 'dimensions',
        label: 'Dimensions',
        visible: true,
        searchable: true,
        index: 22)
    defs << ElementDef.new(
        name: 'educationLevel',
        label: 'Education Level',
        visible: true,
        searchable: true,
        index: 23,
        facetable: true)
    defs << ElementDef.new(
        name: 'extent',
        label: 'Extent',
        visible: true,
        searchable: true,
        index: 24)
    defs << ElementDef.new(
        name: 'format',
        label: 'Format',
        visible: true,
        searchable: true,
        index: 25,
        facetable: true)
    defs << ElementDef.new(
        name: 'hasFormat',
        label: 'Has Format',
        visible: true,
        searchable: true,
        index: 26)
    defs << ElementDef.new(
        name: 'hasPart',
        label: 'Has Part',
        visible: true,
        searchable: true,
        index: 27)
    defs << ElementDef.new(
        name: 'hasVersion',
        label: 'Has Version',
        visible: true,
        searchable: true,
        index: 28)
    defs << ElementDef.new(
        name: 'identifier',
        label: 'Identifier',
        visible: true,
        searchable: true,
        sortable: true,
        index: 29)
    defs << ElementDef.new(
        name: 'instructionalMethod',
        label: 'Instructional Method',
        visible: true,
        searchable: true,
        index: 30)
    defs << ElementDef.new(
        name: 'isFormatOf',
        label: 'Is Format Of',
        visible: true,
        searchable: true,
        index: 31)
    defs << ElementDef.new(
        name: 'isPartOf',
        label: 'Is Part Of',
        visible: true,
        searchable: true,
        index: 32)
    defs << ElementDef.new(
        name: 'isReferencedBy',
        label: 'Is Referenced By',
        visible: true,
        searchable: true,
        index: 33)
    defs << ElementDef.new(
        name: 'isReplacedBy',
        label: 'Is Replaced By',
        visible: true,
        searchable: true,
        index: 34)
    defs << ElementDef.new(
        name: 'isRequiredBy',
        label: 'Is Required By',
        visible: true,
        searchable: true,
        index: 35)
    defs << ElementDef.new(
        name: 'isVersionOf',
        label: 'Is Version Of',
        visible: true,
        searchable: true,
        index: 36)
    defs << ElementDef.new(
        name: 'language',
        label: 'Language',
        visible: true,
        searchable: true,
        index: 37,
        facetable: true)
    defs << ElementDef.new(
        name: 'latitude',
        label: 'Latitude',
        visible: true,
        searchable: true,
        sortable: true,
        index: 38)
    defs << ElementDef.new(
        name: 'license',
        label: 'License',
        visible: true,
        searchable: true,
        index: 39)
    defs << ElementDef.new(
        name: 'longitude',
        label: 'Longitude',
        visible: true,
        searchable: true,
        sortable: true,
        index: 40)
    defs << ElementDef.new(
        name: 'mediator',
        label: 'Mediator',
        visible: true,
        searchable: true,
        index: 41)
    defs << ElementDef.new(
        name: 'medium',
        label: 'Medium',
        visible: true,
        searchable: true,
        index: 42)
    defs << ElementDef.new(
        name: 'notes',
        label: 'Notes',
        visible: true,
        searchable: true,
        index: 43)
    defs << ElementDef.new(
        name: 'physicalLocation',
        label: 'Physical Location',
        visible: true,
        searchable: true,
        index: 44)
    defs << ElementDef.new(
        name: 'provenance',
        label: 'Provenance',
        visible: true,
        searchable: true,
        index: 45)
    defs << ElementDef.new(
        name: 'publicationPlace',
        label: 'Publication Place',
        visible: true,
        searchable: true,
        index: 46)
    defs << ElementDef.new(
        name: 'publisher',
        label: 'Publisher',
        visible: true,
        searchable: true,
        index: 47,
        facetable: true)
    defs << ElementDef.new(
        name: 'references',
        label: 'References',
        visible: true,
        searchable: true,
        index: 48)
    defs << ElementDef.new(
        name: 'relation',
        label: 'Relation',
        visible: true,
        searchable: true,
        index: 49)
    defs << ElementDef.new(
        name: 'replaces',
        label: 'Replaces',
        visible: true,
        searchable: true,
        index: 50)
    defs << ElementDef.new(
        name: 'requires',
        label: 'Requires',
        visible: true,
        searchable: true,
        index: 51)
    defs << ElementDef.new(
        name: 'rights',
        label: 'Rights',
        visible: true,
        searchable: true,
        index: 52)
    defs << ElementDef.new(
        name: 'rightsHolder',
        label: 'Rights Holder',
        visible: true,
        searchable: true,
        index: 53)
    defs << ElementDef.new(
        name: 'source',
        label: 'Source',
        visible: true,
        searchable: true,
        index: 54,
        facetable: true)
    defs << ElementDef.new(
        name: 'spatialCoverage',
        label: 'Spatial Coverage',
        visible: true,
        searchable: true,
        index: 55)
    defs << ElementDef.new(
        name: 'subject',
        label: 'Subject',
        visible: true,
        searchable: true,
        index: 56,
        facetable: true)
    defs << ElementDef.new(
        name: 'tableOfContents',
        label: 'Table Of Contents',
        visible: true,
        searchable: true,
        index: 57)
    defs << ElementDef.new(
        name: 'temporalCoverage',
        label: 'Temporal Coverage',
        visible: true,
        searchable: true,
        index: 58)
    defs << ElementDef.new(
        name: 'title',
        label: 'Title',
        visible: true,
        searchable: true,
        sortable: true,
        index: 59)
    defs << ElementDef.new(
        name: 'type',
        label: 'Type',
        visible: true,
        searchable: true,
        index: 60,
        facetable: true)
  end

  ##
  # Overrides parent to intelligently clone a metadata profile including all
  # of its elements.
  #
  # @return [MetadataProfile]
  #
  def dup
    clone = super
    clone.default = false
    self.element_defs.each { |t| clone.element_defs << t.dup }
    clone
  end

  def solr_facet_fields
    self.element_defs.select{ |d| d.facetable }.map{ |d| d.solr_facet_field }
  end

  private

  def add_default_element_defs
    MetadataProfile.default_element_defs.each do |ed|
      ed.metadata_profile = self
      ed.save!
    end
  end

  ##
  # Makes all other instances "not default" if the instance is the default.
  #
  def ensure_default_uniqueness
    if self.default
      self.class.all.where('id != ?', self.id).each do |instance|
        instance.default = false
        instance.save!
      end
    end
  end

end
