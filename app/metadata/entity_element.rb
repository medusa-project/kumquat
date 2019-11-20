##
# Encapsulates a metadata element attached to an entity such as an Item or
# Collection. An element has a name matching any of the Element names.
#
# This class is "abstract" and intended to be used as a base class with
# single-table inheritance.
#
class EntityElement < ApplicationRecord

  belongs_to :vocabulary, optional: true

  INDEX_FIELD_PREFIX   = 'metadata_'
  KEYWORD_FIELD_SUFFIX = '.keyword'
  SORT_FIELD_SUFFIX    = '.sort'

  validates_presence_of :name

  ##
  # @param field [String] Indexed keyword field name.
  # @return [String] Element name.
  #
  def self.element_name_for_indexed_field(field)
    field.gsub(INDEX_FIELD_PREFIX, '')
  end

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
        string = "#{string}#{ItemTsvExporter::URI_VALUE_SEPARATOR}#{uri}"
      end
      if string.blank? and uri.present?
        string = uri
      end
      if string.present?
        values << string
      end
    end
    values.join(ItemTsvExporter::MULTI_VALUE_SEPARATOR)
  end

  def agent
    agent = nil
    if self.uri.present?
      agent = AgentUri.find_by_uri(self.uri)&.agent
    end
    agent
  end

  def as_json(options = {})
    struct = super(options)
    struct['string'] = self.value
    struct['uri'] = self.uri
    struct['vocabulary'] = self.vocabulary&.key || Vocabulary::uncontrolled.key
    struct.except('value')
  end

  ##
  # @return [String] Name of the indexed field for the instance.
  # @see indexed_keyword_field()
  #
  def indexed_field
    [INDEX_FIELD_PREFIX, self.name].join
  end

  ##
  # @return [String] Name of the indexed keyword field for the instance.
  # @see indexed_field()
  #
  def indexed_keyword_field
    [INDEX_FIELD_PREFIX, self.name, KEYWORD_FIELD_SUFFIX].join
  end

  ##
  # @return [String] Name of the indexed sort field for the instance.
  # @see indexed_field()
  #
  def indexed_sort_field
    [INDEX_FIELD_PREFIX, self.name, SORT_FIELD_SUFFIX].join
  end

  ##
  # @return [String] Name of the parent indexed field for the instance.
  #
  def parent_indexed_field
    [INDEX_FIELD_PREFIX, 'parent_', self.name].join
  end

  def serializable_hash(opts)
    opts ||= {}
    super(opts.merge(only: [ :name, :value ]))
  end

  def to_s
    self.value.to_s
  end

end