class Agent < ActiveRecord::Base

  include SolrQuerying

  class SolrFields
    CLASS = 'class_si'
    DESCRIPTION = "#{EntityElement::solr_prefix}_description_txti"
    NAME = "#{EntityElement::solr_prefix}_title_txti"
    ID = 'id'
  end

  belongs_to :agent_rule, inverse_of: :agents
  belongs_to :agent_type, inverse_of: :agents

  has_many :agent_relations, class_name: 'AgentRelation',
           foreign_key: :agent_id, dependent: :destroy
  has_many :related_agents, -> { order(name: :asc) },
           through: :agent_relations, source: :related_agent
  has_many :agent_uris, -> { order(primary: :desc) }, inverse_of: :agent,
           dependent: :destroy

  before_validation :ascribe_default_uri, if: :new_record?

  validates_presence_of :name

  after_commit :index_in_solr, on: [:create, :update]
  after_commit :delete_from_solr, on: :destroy

  ##
  # @param id [String]
  # @return [Agent]
  #
  def self.find_by_repository_id(id)
    # This logic must be kept in sync with that of solr_id().
    Agent.find(id.gsub(/[^0-9]/, ''))
  end

  def delete_from_solr
    Solr.instance.delete(self.solr_id)
  end

  ##
  # Implemented to assist in cross-entity search.
  #
  # @return [self]
  #
  def effective_representative_item
    self
  end

  ##
  # @return [void]
  #
  def index_in_solr
    Solr.instance.add(self.to_solr)
  end

  ##
  # @return [String, nil] The agent's primary URI, or one if its URIs if none
  #                       are marked as primary; or nil if the agent has no
  #                       URIs.
  #
  def primary_uri
    self.agent_uris.select(&:primary).first&.uri || self.agent_uris.first&.uri
  end

  ##
  # @return [Enumerable<Collection>]
  #
  def related_collections
    Collection.joins('LEFT JOIN entity_elements ON entity_elements.collection_id = collections.id').
        where('entity_elements.uri IN (?)', self.agent_uris.map(&:uri))
  end

  ##
  # @return [Enumerable<Item>]
  #
  def related_objects
    Item.joins('LEFT JOIN entity_elements ON entity_elements.item_id = items.id').
        where('entity_elements.uri IN (?)', self.agent_uris.map(&:uri)).
        where('variant IS NULL OR variant = ? OR variant IN (?)', '',
              [Item::Variants::DIRECTORY, Item::Variants::FILE])
  end

  ##
  # @return [String]
  #
  def solr_id
    # This logic must be kept in sync with that of find_by_repository_id().
    "agent-#{self.id}"
  end

  ##
  # Alias of name().
  #
  # @return [String]
  #
  def title
    name
  end

  ##
  # @return [Hash]
  #
  def to_solr
    doc = {}
    doc[SolrFields::ID] = self.solr_id
    doc[SolrFields::CLASS] = self.class.to_s
    doc[SolrFields::DESCRIPTION] = self.description.to_s
    doc[SolrFields::NAME] = self.name.to_s
    doc
  end

  private

  def ascribe_default_uri
    if self.agent_uris.empty?
      self.agent_uris.build(uri: "urn:uuid:#{SecureRandom.uuid}", primary: true)
    end
  end

end
