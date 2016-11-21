##
# Encapsulates a metadata element attached to an item. An element has a name
# matching any of the Element names.
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
class ItemElement < ActiveRecord::Base

  class Type
    DESCRIPTIVE = 0
    TECHNICAL = 1
  end

  belongs_to :item, inverse_of: :elements, touch: true
  belongs_to :vocabulary

  attr_accessor :type

  @@element_properties = YAML::load_file(File.join(__dir__, 'metadata.yml'))

  validates_presence_of :name

  ##
  # @return [Enumerable<ItemElement>]
  #
  def self.all_available
    # Technical elements
    all_elements = @@element_properties.map do |name, props|
      ItemElement.new(name: name, type: Type::TECHNICAL)
    end
    # Descriptive elements
    all_elements += all_descriptive
    all_elements
  end

  ##
  # @return [Enumerable<ItemElement>]
  #
  def self.all_descriptive
    Element.all.map do |elem|
      ItemElement.new(name: elem.name, type: Type::DESCRIPTIVE)
    end
  end

  ##
  # @param element_name [String] Element name
  # @param string [String] TSV string
  # @param vocabulary_override [Vocabulary] Optionally override any voabularies
  #                                         specified in the string with this
  #                                         one.
  # @return [Enumerable<ItemElement>]
  # @raises [ArgumentError] If an element with the given name does not exist,
  #                         or an invalid vocabulary key is provided.
  #
  def self.elements_from_tsv_string(element_name, string,
      vocabulary_override = nil)
    unless ItemElement.all_descriptive.map(&:name).include?(element_name)
      raise ArgumentError, "Element does not exist: #{element_name}"
    end

    elements = []
    if string.present?
      string.split(Item::TSV_MULTI_VALUE_SEPARATOR).select(&:present?).each do |raw_value|
        e = ItemElement.named(element_name)
        # raw_value may be an arbitrary string; it may be a URI (enclosed
        # in angle brackets); or it may be both, joined with
        # Item::TSV_URI_VALUE_SEPARATOR.
        value_parts = raw_value.split(Item::TSV_URI_VALUE_SEPARATOR)
        value_parts.each do |part|
          if part.start_with?('<') and part.end_with?('>') and part.length > 2
            e.uri = part[1..part.length - 2]
          elsif part.present?
            # part may be prefixed with a vocabulary key.
            subparts = part.split(':')
            if subparts.length > 1
              e.vocabulary = vocabulary_override || Vocabulary.find_by_key(subparts[0])
              e.value = subparts[1..subparts.length].join(':')
            else
              e.vocabulary = vocabulary_override || Vocabulary::uncontrolled
              e.value = part
            end
          end
        end
        elements << e
      end
    end
    elements
  end

  ##
  # @return [ItemElement] ItemElement with the given name, or nil if the given
  #                       name is not an available technical or descriptive
  #                       element name.
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

  def ==(obj)
    obj.kind_of?(ItemElement) and obj.name == self.name and
        obj.value == self.value and obj.uri == self.uri and
        obj.vocabulary_id == self.vocabulary_id
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
    "#{self.name}#{ItemElement.solr_suffix}#{ItemElement.solr_facet_suffix}"
  end

  ##
  # @return [String] Name of the multi-valued Solr field.
  #
  def solr_multi_valued_field
    "#{ItemElement.solr_prefix}#{self.name}#{ItemElement.solr_suffix}"
  end

  ##
  # @return [String] Name of the single-valued Solr field.
  #
  def solr_single_valued_field
    "#{ItemElement.solr_prefix}#{self.name}#{ItemElement.solr_sortable_suffix}"
  end

  def to_s
    self.value.to_s
  end

end