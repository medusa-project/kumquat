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
