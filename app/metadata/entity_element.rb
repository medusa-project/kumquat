# frozen_string_literal: true

##
# Encapsulates a metadata element attached to an entity such as an {Item} or
# {Collection}. Has a name matching any of the {Element} names.
#
# This class is "abstract" and intended to be used as a base class with
# single-table inheritance.
#
# # Attributes
#
# * `collection_id` Foreign key to {Collection} for {CollectionElement}s/
# * `created_at`    Managed by ActiveRecord.
# * `item_id`       Foreign key to {Item} for {ItemElement}s.
# * `name`          Element name, which must be one of the {Element} names.
# * `type`          Rails single-table inheritance column.
# * `updated_at`    Managed by ActiveRecord.
# * `uri`           URI value.
# * `value`         String value.
# * `vocabulary_id` Foreign key to {Vocabulary} for constraining the value to
#                   a term in that vocabulary.
#
class EntityElement < ApplicationRecord

  belongs_to :vocabulary, optional: true

  # Contains controlled rights information in the RightsStatements.org or
  # Creative Commons vocabulary. This is more of a vestigial suggestion than
  # anything else, as the name of the element associated with one of these
  # vocabularies is no longer important, generally. But accessRights has been
  # the historical convention.
  CONTROLLED_RIGHTS_ELEMENT = "accessRights"

  INDEX_FIELD_PREFIX        = "metadata_"
  KEYWORD_FIELD_SUFFIX      = ".keyword"
  SORT_FIELD_SUFFIX         = ".sort"

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
      if string.present? && e.vocabulary && e.vocabulary != Vocabulary::uncontrolled
        string = "#{e.vocabulary.key}:#{string}"
      end
      uri = e.uri
      if uri.present?
        uri = "<#{uri}>"
      end
      if string.present? && uri.present?
        string = "#{string}#{ItemTsvExporter::URI_VALUE_SEPARATOR}#{uri}"
      end
      if string.blank? && uri.present?
        string = uri
      end
      if string.present?
        values << string
      end
    end
    values.join(ItemTsvExporter::MULTI_VALUE_SEPARATOR)
  end

  ##
  # @return [Agent]
  #
  def agent
    agent = nil
    if self.uri.present?
      agent = AgentUri.find_by_uri(self.uri)&.agent
    end
    agent
  end

  def as_json(options = {})
    struct               = super(options)
    struct['string']     = self.value
    struct['uri']        = self.uri
    struct['vocabulary'] = self.vocabulary&.key || Vocabulary::uncontrolled.key
    struct.except('value')
  end

  ##
  # @return [String] Name of the indexed field for the instance.
  # @see indexed_keyword_field
  #
  def indexed_field
    [INDEX_FIELD_PREFIX,
     self.name.gsub(OpensearchClient::RESERVED_CHARACTERS, "_")].join
  end

  ##
  # @return [String] Name of the indexed keyword field for the instance.
  # @see indexed_field
  #
  def indexed_keyword_field
    [INDEX_FIELD_PREFIX,
     self.name.gsub(OpensearchClient::RESERVED_CHARACTERS, "_"),
     KEYWORD_FIELD_SUFFIX].join
  end

  ##
  # @return [String] Name of the indexed sort field for the instance.
  # @see indexed_field
  #
  def indexed_sort_field
    [INDEX_FIELD_PREFIX,
     self.name.gsub(OpensearchClient::RESERVED_CHARACTERS, "_"),
     SORT_FIELD_SUFFIX].join
  end

  ##
  # @return [String] Name of the parent indexed field for the instance.
  #
  def parent_indexed_field
    [INDEX_FIELD_PREFIX,
     'parent_',
     self.name.gsub(OpensearchClient::RESERVED_CHARACTERS, "_")].join
  end

  def serializable_hash(opts)
    opts ||= {}
    super(opts.merge(only: [:name, :value]))
  end

  def to_s
    self.value.to_s
  end

end