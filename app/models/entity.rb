##
# Abstract base class from which items and collections inherit.
#
class Entity

  class SolrFields
    CLASS = 'class_si'
    ID = 'id'
    LAST_INDEXED = 'last_indexed_dti'
    SEARCH_ALL = 'searchall_txtim'
  end

  extend ActiveModel::Callbacks

  include ActiveModel::Model
  include ActiveModel::Serialization
  include GlobalID::Identification
  include Deserialization
  include SolrQuerying

  attr_accessor :id # String
  attr_accessor :last_indexed # Time
  attr_accessor :score # Float

  def self.from_solr(doc)
    class_field = PearTree::Application.peartree_config[:solr_class_field]
    class_ = doc[class_field].constantize
    class_.from_solr(doc)
  end

  def initialize
    @persisted = false
  end

  def destroy
    Solr.instance.delete(self.id)
  end

  def persisted?
    @persisted # makes to_param work
  end

  def save
    Solr.instance.add(self.to_solr)
  end

  def to_param
    self.id.to_s
  end

  ##
  # @return [String] The title.
  #
  def to_s
    self.title
  end

  ##
  # @return [Hash]
  #
  def to_solr
    doc = {}
    doc[Entity::SolrFields::ID] = self.id
    doc[Entity::SolrFields::CLASS] = self.class.to_s
    doc[Entity::SolrFields::LAST_INDEXED] = DateTime.now.utc.iso8601 + 'Z'
    doc
  end

end
