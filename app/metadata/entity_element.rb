##
# Encapsulates a metadata element attached to an entity such as an Item or
# Collection. An element has a name matching any of the Element names.
#
# This class is "abstract" and intended to be used as a base class with
# single-table inheritance.
#
class EntityElement < ActiveRecord::Base

  belongs_to :vocabulary

  validates_presence_of :name

  ##
  # @param elements [Enumerable<ItemElement>] Collection of elements. All must
  #                                           have the same name.
  # @return [String]
  # @raises [ArgumentError] If elements with different names are provided.
  #
  def self.tsv_string_from_elements(elements)
    if elements.to_a.map(&:name).uniq.length > 1
      raise ArgumentError, 'Elements must all have the same name'
    end

    values = []
    elements.each do |e|
      string = e.value
      if string.present? and e.vocabulary and
          e.vocabulary != Vocabulary::uncontrolled
        string = "#{e.vocabulary.key}:#{string}"
      end
      uri = e.uri
      if uri.present?
        uri = "<#{uri}>"
      end
      if string.present? and uri.present?
        string = "#{string}#{Item::TSV_URI_VALUE_SEPARATOR}#{uri}"
      end
      if string.blank? and uri.present?
        string = uri
      end
      if string.present?
        values << string
      end
    end
    values.join(Item::TSV_MULTI_VALUE_SEPARATOR)
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

  def serializable_hash(opts)
    opts ||= {}
    super(opts.merge(only: [ :name, :value ]))
  end

  ##
  # @return [String] Name of the Solr facet field.
  #
  def solr_facet_field
    "#{self.name}#{EntityElement.solr_suffix}#{EntityElement.solr_facet_suffix}"
  end

  ##
  # @return [String] Name of the multi-valued Solr field.
  #
  def solr_multi_valued_field
    "#{EntityElement.solr_prefix}#{self.name}#{EntityElement.solr_suffix}"
  end

  ##
  # @return [String] Name of the single-valued Solr field.
  #
  def solr_single_valued_field
    "#{EntityElement.solr_prefix}#{self.name}#{EntityElement.solr_sortable_suffix}"
  end

  def to_s
    self.value.to_s
  end

end