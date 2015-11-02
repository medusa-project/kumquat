##
# Abstract base class from which items and collections inherit.
#
class Entity

  extend ActiveModel::Callbacks

  include ActiveModel::Model
  include GlobalID::Identification
  include Deserialization
  include SolrQuerying

  attr_accessor :id # String
  attr_accessor :date # Date
  attr_accessor :description # String
  attr_reader :metadata # Array
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
    @metadata = {}
    @persisted = false
  end

  def description
    metadata_values(:dc, :description).first ||
        metadata_values(:dcterms, :description).first
  end

  def index_in_solr
    Solr.client.add(self.to_solr)
  end

  def metadata_values(element_set, element)
    element_set = element_set.to_s
    element = element.to_s
    if self.metadata.keys.include?(element_set)
      if self.metadata[element_set].keys.include?(element)
        return self.metadata[element_set][element]
      end
    end
    []
  end

  def persisted?
    @persisted # makes to_param work
  end

  def subtitle
    metadata_values(:dcterms, :alternative).first
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
    doc[Solr::Fields::LAST_INDEXED] = DateTime.now.utc.iso8601 + 'Z'
    doc[Solr::Fields::PUBLISHED] = self.published
    doc[Solr::Fields::TITLE] = self.title
    doc[Solr::Fields::WEB_ID] = self.web_id

    self.metadata.keys.each do |element_set|
      self.metadata[element_set].keys.each do |element|
        doc["#{element_set}_#{element}_txtim"] = self.metadata[element_set][element]
      end
    end

    doc
  end

  def web_id
    @web_id || self.id
  end

end
