class Element < ActiveRecord::Base

  class Type
    DESCRIPTIVE = 0
    TECHNICAL = 1
  end

  belongs_to :item, inverse_of: :elements

  attr_accessor :type

  @@element_properties = YAML::load_file(File.join(__dir__, 'metadata.yml'))

  validates_presence_of :name

  ##
  # @return [Array<Element>]
  #
  def self.all_available
    # Technical elements
    all_elements = @@element_properties.map do |name, props|
      Element.new(name: name, type: Type::TECHNICAL)
    end
    # Descriptive elements
    all_elements += all_descriptive
    all_elements
  end

  ##
  # @return [Array<Element>]
  #
  def self.all_descriptive
    AvailableElement.all.map do |elem|
      Element.new(name: elem.name, type: Type::DESCRIPTIVE)
    end
  end

  ##
  # @return [Element] Element with the given name, or nil if the given name is
  #                   not an available technical or descriptive element name.
  #
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