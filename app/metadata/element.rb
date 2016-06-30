##
# Encapsulates a metadata element attached to an item. An element has a name
# matching any of the AvailableElement names.
#
# To add technical elements:
# 1) Add a column for it on Item
# 2) Add it to Item::SolrFields
# 3) Add it to app/metadata/metadata.yml
# 4) Add it to one of the XSDs in /public
# 5) Add serialization code to Item.tsv_header, to_tsv, to_xml, and to_solr
# 6) Add deserialization code to Item.update_from_tsv and update_from_xml
# 7) Update fixtures and tests
# 8) Reindex, if necessary
#
class Element < ActiveRecord::Base

  class Type
    DESCRIPTIVE = 0
    TECHNICAL = 1
  end

  belongs_to :item, inverse_of: :elements
  belongs_to :vocabulary

  attr_accessor :type

  @@element_defs = YAML::load_file(File.join(__dir__, 'metadata.yml'))

  validates_presence_of :name

  def self.all_available
    all_elements = []
    @@element_defs.each do |name, defs|
      e = Element.new
      e.name = name
      e.type = (defs['type'] == 'descriptive') ?
          Type::DESCRIPTIVE : Type::TECHNICAL
      all_elements << e
    end
    all_elements
  end

  def self.all_descriptive
    all_available.select{ |e| e.type == Type::DESCRIPTIVE }
  end

  def self.named(name)
    all_available.select{ |e| e.name == name }.first
  end

  def self.solr_facet_suffix
    '_facet'
  end

  def self.solr_prefix
    'metadata_'
  end

  def self.solr_sortable_suffix
    '_si'
  end

  def self.solr_suffix
    '_txtim'
  end

  def formatted_value
    case self.name
      when 'latitude'
        val = "#{self.value.gsub('-', '')}°#{self.value.to_f >= 0 ? 'N' : 'S'}"
      when 'longitude'
        val = "#{self.value.gsub('-', '')}°#{self.value.to_f >= 0 ? 'E' : 'W'}"
      else
        val = self.value
    end
    val
  end

  def serializable_hash(opts)
    opts ||= {}
    super(opts.merge(only: [ :name, :value ]))
  end

  ##
  # @return [String] Name of the Solr facet field.
  #
  def solr_facet_field
    "#{self.name}#{Element.solr_suffix}#{Element.solr_facet_suffix}"
  end

  ##
  # @return [String] Name of the multi-valued Solr field.
  #
  def solr_multi_valued_field
    "#{Element.solr_prefix}#{self.name}#{Element.solr_suffix}"
  end

  ##
  # @return [String] Name of the single-valued Solr field.
  #
  def solr_single_valued_field
    "#{Element.solr_prefix}#{self.name}#{Element.solr_sortable_suffix}"
  end

  def to_s
    self.value.to_s
  end

end