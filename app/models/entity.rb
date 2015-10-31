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

  attr_accessor :access_master_media_type # String
  attr_accessor :access_master_pathname # String
  attr_accessor :id # String
  attr_accessor :date # Date
  attr_accessor :full_text # String
  attr_accessor :preservation_master_media_type # String
  attr_accessor :preservation_master_pathname # String
  attr_accessor :score # float
  attr_accessor :title # String
  attr_accessor :web_id # String

  def initialize
    @persisted = false
  end

  ##
  # @param id [String]
  # @param class_ [Class]
  #
  def self.load(id, class_)
    class_.new # TODO: write this
  end

  def persisted?
    @persisted # makes to_param work
  end

  def to_param
    (self.web_id || self.id).parameterize
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
    doc['id'] = self.id
    doc['class_si'] = self.class.to_s
    doc['title_txti'] = self.title
    doc['web_id_si'] = self.web_id
    doc
  end

end
