##
# A metadata profile defines a set of metadata elements, their labels, their
# mappings to other schemas, and whether they are searchable, sortable, etc.
# Metadata profiles are assigned to collections and control things like
# faceting; which fields appear in a TSV export; how local elements map to DC
# in the OAI-PMH endpoint; etc.
#
# A metadata profile is like a template or view. Instead of enumerating an
# Item's metadata elements for public display, we enumerate the elements in its
# collection's metadata profile, and display each of its elements that match,
# in the order defined by the profile.
#
class MetadataProfile < ApplicationRecord

  belongs_to :default_sortable_element, class_name: 'MetadataProfileElement'
  has_many :collections, inverse_of: :metadata_profile,
           dependent: :restrict_with_exception
  has_many :elements, -> { order(:index) },
           class_name: 'MetadataProfileElement',
           inverse_of: :metadata_profile,
           dependent: :destroy

  validates :name, presence: true, length: { minimum: 2 },
            uniqueness: { case_sensitive: false }

  validate :using_valid_elements

  after_save :ensure_default_uniqueness

  ##
  # @return [MetadataProfile]
  #
  def self.default
    MetadataProfile.find_by_default(true)
  end

  ##
  # @return [Enumerable<MetadataProfileElement>]
  #
  def self.default_elements
    defs = []
    ItemElement.all_available.each_with_index do |elem, index|
      dc_map = DublinCoreElement.all.map(&:name).include?(elem.name) ? elem.name : nil
      dcterms_map = DublinCoreTerm.all.map(&:name).include?(elem.name) ? elem.name : nil
      profile_elem = MetadataProfileElement.new(
          name: elem.name,
          label: elem.name.titleize,
          visible: true,
          searchable: true,
          sortable: true,
          facetable: true,
          dc_map: dc_map,
          dcterms_map: dcterms_map,
          vocabularies: [ Vocabulary.uncontrolled ],
          index: index)
      # Add the RightsStatements.org vocabulary to the `rights` element.
      if profile_elem.name == 'rights'
        rights_vocab = Vocabulary.find_by_key('rights')
        profile_elem.vocabularies << rights_vocab if rights_vocab
      end
      defs << profile_elem
    end
    defs
  end

  ##
  # @param json [String] JSON string from as_json()
  # @return [MetadataProfile] Persisted MetadataProfile
  # @raises [RuntimeError] If a vocabulary associated with an element does not
  #                        exist
  #
  def self.from_json(json)
    struct = JSON.parse(json)
    profile = MetadataProfile.new

    ActiveRecord::Base.transaction do
      # Ensure that its name is unique.
      tentative_name = "#{struct['name']} (imported)"
      index = 1
      loop do
        if MetadataProfile.find_by_name(tentative_name)
          tentative_name = "#{struct['name']} (imported) (#{index})"
          index += 1
        else
          break
        end
      end
      profile.name = tentative_name

      # Save now to get an ID, which elements will need to perform validations
      # in the next step.
      profile.save!

      # Add its elements.
      struct['elements'].each do |jd|
        profile_elem = profile.elements.build
        profile_elem.name = jd['name']
        profile_elem.label = jd['label']
        profile_elem.index = jd['index']
        profile_elem.searchable = jd['searchable']
        profile_elem.facetable = jd['facetable']
        profile_elem.visible = jd['visible']
        profile_elem.sortable = jd['sortable']
        profile_elem.dc_map = jd['dc_map']
        profile_elem.dcterms_map = jd['dcterms_map']
        jd['vocabularies'].each do |v|
          vocab = Vocabulary.find_by_key(v['key'])
          if vocab
            profile_elem.vocabularies << vocab
          else
            raise "Vocabulary does not exist: #{v['key']}"
          end
        end
        profile_elem.save!
        if jd['id'] == struct['default_sortable_element_id']
          profile.default_sortable_element_id = profile_elem.id
        end
      end
      profile.save!
    end
    profile
  end

  ##
  # Will save the instance of its ID is nil.
  #
  # @return [void]
  #
  def add_default_elements
    ActiveRecord::Base.transaction do
      # The instance requires an ID for MetadataProfileElement validations.
      self.save! if self.id.nil?
      MetadataProfile.default_elements.each do |ed|
        unless self.elements.map(&:name).include?(ed.name)
          self.elements << ed
        end
      end
      self.save!
    end
  end

  ##
  # Overrides parent to serialize an instance to JSON with its child
  # MetadataProfileElements included.
  #
  # @param options [Hash]
  # @return [String]
  #
  def as_json(options = {})
    super(options.merge(include: {
        elements: {
          include: :vocabularies
        }
    }))
  end

  ##
  # Overrides parent to intelligently clone a metadata profile including all
  # of its elements.
  #
  # @return [MetadataProfile]
  #
  def dup
    clone = super
    clone.name = "Clone of #{self.name}"
    clone.default = false
    # The instance requires an ID for MetadataProfileElement validations.
    clone.save!
    self.elements.each { |t| clone.elements << t.dup }
    clone
  end

  def solr_facet_fields
    self.elements.select{ |d| d.facetable }.map{ |d| d.solr_facet_field }
  end

  private

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

  ##
  # Ensures that each of the instance's elements has a corresponding [Element].
  #
  def using_valid_elements
    self.elements.each do |pe|
      unless Element.find_by_name(pe.name)
        errors.add(:name, "\"#{pe.name}\" is not a valid DLS element.")
      end
    end
  end

end
