##
# A metadata profile defines a set of metadata elements, their labels, their
# mappings to other schemas, whether they are searchable, sortable, etc.
# Metadata profiles are assigned to collections and control things like
# faceting; which fields appear in a TSV export, and are accepted in a TSV
# import; how local elements map to DC in the OAI-PMH endpoint; etc.
#
# A metadata profile is like a template. For example, instead of enumerating
# an Item's metadata elements for public display, we would enumerate the
# elements in its collection's metadata profile, and display each of its
# elements that match, in the order defined by the profile.
#
class MetadataProfile < ActiveRecord::Base

  belongs_to :default_sortable_element_def, class_name: 'ElementDef'
  has_many :collections, inverse_of: :metadata_profile,
           dependent: :restrict_with_error
  has_many :element_defs, -> { order(:index) }, inverse_of: :metadata_profile,
           dependent: :destroy

  validates :name, presence: true, length: { minimum: 2 },
            uniqueness: { case_sensitive: false }

  after_save :ensure_default_uniqueness

  @@default_defs = YAML::load_file(File.join(__dir__, 'metadata.yml'))

  def self.default
    MetadataProfile.find_by_default(true)
  end

  def self.default_element_defs
    defs = []
    index = 0
    @@default_defs.select{ |k, v| v['type'] == 'descriptive' }.
        each do |name, props|
      defs << ElementDef.new(name: name,
                             label: props['label'],
                             visible: props['visible'],
                             searchable: props['searchable'],
                             sortable: props['sortable'],
                             facetable: props['facetable'],
                             dc_map: props['mappings']['dc'],
                             dcterms_map: props['mappings']['dcterms'],
                             index: index)
      index += 1
    end
    defs
  end

  ##
  # @param json [String] JSON string from as_json()
  # @return [MetadataProfile] Persisted MetadataProfile
  #
  def self.from_json(json)
    struct = JSON.parse(json)
    profile = MetadataProfile.new

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
      ed.save!
      if jd['id'] == struct['default_sortable_element_def_id']
        profile.default_sortable_element_def_id = ed.id
      end
    end
    profile.save!
    profile
  end

  def add_default_element_defs
    MetadataProfile.default_element_defs.each do |ed|
      ed.metadata_profile = self
      ed.save!
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
    super(options.merge(include: :element_defs))
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
