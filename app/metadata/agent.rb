class Agent < ActiveRecord::Base

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
        where('variant IS NULL OR variant IN (?)',
              [Item::Variants::DIRECTORY, Item::Variants::FILE])
  end

  private

  def ascribe_default_uri
    if self.agent_uris.empty?
      self.agent_uris.build(uri: "urn:uuid:#{SecureRandom.uuid}", primary: true)
    end
  end

end
