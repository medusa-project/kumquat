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
  attr_accessor :created # DateTime
  attr_accessor :date # Date
  attr_accessor :description # String
  attr_accessor :last_modified # DateTime
  attr_reader :metadata # Array
  attr_accessor :published # Boolean
  attr_accessor :representative_item_id # String
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
    @metadata = []
    @persisted = false
  end

  def description
    elements = metadata.select{ |e| e.name == 'description' }
    elements.any? ? elements.first.value : nil
  end

  def destroy
    Solr.instance.delete(self.id)
  end

  def persisted?
    @persisted # makes to_param work
  end

  def representative_item
    Item.find_by_id(self.representative_item_id)
  end

  def save
    Solr.instance.add(self.to_solr)
  end

  def subtitle
    elements = metadata.select{ |e| e.name == 'alternativeTitle' }
    elements.any? ? elements.first.value : nil
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
    doc[Solr::Fields::CREATED] = self.created.utc.iso8601 + 'Z' if self.created
    doc[Solr::Fields::LAST_INDEXED] = DateTime.now.utc.iso8601 + 'Z'
    if self.last_modified
      doc[Solr::Fields::LAST_MODIFIED] = self.last_modified.utc.iso8601 + 'Z'
    end
    doc[Solr::Fields::PUBLISHED] = self.published
    doc[Solr::Fields::REPRESENTATIVE_ITEM_ID] = self.representative_item_id
    doc[Solr::Fields::TITLE] = self.title
    doc[Solr::Fields::WEB_ID] = self.web_id

    self.metadata.each do |element|
      doc[element.solr_name] ||= []
      doc[element.solr_name] << element.value
    end

    doc
  end

  def web_id
    @web_id || self.id
  end

end
