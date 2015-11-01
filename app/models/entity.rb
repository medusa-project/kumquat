##
# Abstract base class from which items and collections inherit.
#
class Entity

  extend ActiveModel::Callbacks

  include ActiveModel::Model
  include GlobalID::Identification
  include Deserialization
  include Indexing
  include SolrQuerying

  attr_accessor :id # String
  attr_accessor :date # Date
  attr_accessor :description # String
  attr_accessor :published # Boolean
  attr_accessor :score # float
  attr_accessor :subtitle # String
  attr_accessor :title # String
  attr_accessor :web_id # String

  def self.from_solr(doc)
    class_field = PearTree::Application.peartree_config[:solr_class_field]
    class_ = doc[class_field].constantize
    class_.from_solr(doc)
  end

  def initialize
    @persisted = false
  end

  def persisted?
    @persisted # makes to_param work
  end

  def to_param
    (self.web_id || self.id).to_s
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
    doc[Solr::Fields::ID] = self.id
    doc[Solr::Fields::CLASS] = self.class.to_s
    doc[Solr::Fields::DESCRIPTION] = self.description
    doc[Solr::Fields::LAST_INDEXED] = DateTime.now.utc.iso8601 + 'Z'
    doc[Solr::Fields::PUBLISHED] = self.published
    doc[Solr::Fields::SUBTITLE] = self.subtitle
    doc[Solr::Fields::TITLE] = self.title
    doc[Solr::Fields::WEB_ID] = self.web_id
    doc
  end

  def web_id
    @web_id || self.id
  end

end
