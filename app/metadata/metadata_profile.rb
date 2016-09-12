##
# A metadata profile defines a set of metadata elements, their labels, their
# mappings to other schemas, and whether they are searchable, sortable, etc.
# Metadata profiles are assigned to collections and control things like
# faceting; which fields appear in a TSV export; how local elements map to DC
# in the OAI-PMH endpoint; etc.
#
# A metadata profile is like a template. For example, instead of enumerating
# an Item's metadata elements for public display, we enumerate the elements
# in its collection's metadata profile, and display each of its elements that
# match, in the order defined by the profile.
#
class MetadataProfile < ActiveRecord::Base

  belongs_to :default_sortable_element_def, class_name: 'ElementDef'
  has_many :collections, inverse_of: :metadata_profile,
           dependent: :restrict_with_exception
  has_many :element_defs, -> { order(:index) }, inverse_of: :metadata_profile,
           dependent: :destroy

  validates :name, presence: true, length: { minimum: 2 },
            uniqueness: { case_sensitive: false }

  after_save :ensure_default_uniqueness

  def self.default
    MetadataProfile.find_by_default(true)
  end

  def self.default_element_defs
    defs = []
    ItemElement.all_descriptive.each_with_index do |elem, index|
      dc_map = DublinCoreElement.all.map(&:name).include?(elem.name) ? elem.name : nil
      dcterms_map = DublinCoreTerm.all.map(&:name).include?(elem.name) ? elem.name : nil
      defs << ElementDef.new(name: elem.name,
                             label: elem.name.titleize,
                             visible: true,
                             searchable: true,
                             sortable: true,
                             facetable: true,
                             dc_map: dc_map,
                             dcterms_map: dcterms_map,
                             vocabularies: [ Vocabulary.uncontrolled ],
                             index: index)
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

      # Add its elements.
      struct['element_defs'].each do |jd|
        ed = profile.element_defs.build
        ed.name = jd['name']
        ed.label = jd['label']
        ed.index = jd['index']
        ed.searchable = jd['searchable']
        ed.facetable = jd['facetable']
        ed.visible = jd['visible']
        ed.sortable = jd['sortable']
        ed.dc_map = jd['dc_map']
        ed.dcterms_map = jd['dcterms_map']
        jd['vocabularies'].each do |v|
          vocab = Vocabulary.find_by_key(v['key'])
          if vocab
            ed.vocabularies << vocab
          else
            raise "Vocabulary does not exist: #{v['key']}"
          end
        end
        ed.save!
        if jd['id'] == struct['default_sortable_element_def_id']
          profile.default_sortable_element_def_id = ed.id
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
  def add_default_element_defs
    ActiveRecord::Base.transaction do
      # The instance requires an ID for ElementDef validations.
      self.save! if self.id.nil?
      MetadataProfile.default_element_defs.each do |ed|
        unless self.element_defs.map(&:name).include?(ed.name)
          self.element_defs << ed
        end
      end
      self.save!
    end
  end

  ##
  # Overrides parent to serialize an instance to JSON with its child
  # ElementDefs included.
  #
  # @param options [Hash]
  # @return [String]
  #
  def as_json(options = {})
    super(options.merge(include: {
        element_defs: {
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
    self.element_defs.each { |t| clone.elements << t.dup }
    clone
  end

  def solr_facet_fields
    self.element_defs.select{ |d| d.facetable }.map{ |d| d.solr_facet_field }
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

end
