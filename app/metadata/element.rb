class Element < ActiveRecord::Base

  class Type
    DESCRIPTIVE = 0
    TECHNICAL = 1
  end

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

  def dc_name
    @@element_defs[self.name]['mappings']['dc']
  end

  def dcterms_name
    @@element_defs[self.name]['mappings']['dcterms']
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