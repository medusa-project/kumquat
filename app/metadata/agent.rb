##
# @see https://github.com/elastic/elasticsearch-rails/blob/master/elasticsearch-model/README.md
#
class Agent < ApplicationRecord

  include Elasticsearch::Model
  include Representable

  class IndexFields
    DESCRIPTION = 'description'
    EFFECTIVELY_PUBLISHED = Item::IndexFields::EFFECTIVELY_PUBLISHED
    LAST_INDEXED = 'date_last_indexed'
    NAME = 'name'
    SEARCH_ALL = ElasticsearchIndex::SEARCH_ALL_FIELD
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

  after_commit :index_in_elasticsearch, on: [:create, :update]
  after_commit :delete_from_elasticsearch, on: :destroy

  # Used by the Elasticsearch client for CRUD actions only (not index changes).
  index_name ElasticsearchIndex.current_index(self).name

  ##
  # @param id [String]
  # @return [Agent]
  #
  def self.find_by_repository_id(id)
    # This logic must be kept in sync with that of index_id().
    Agent.find(id.gsub(/[^0-9]/, ''))
  end

  ##
  # @param index [Symbol] :current or :latest
  # @return [void]
  #
  def self.reindex_all(index = :current)
    Agent.uncached do
      count = Agent.count
      Agent.all.find_each.with_index do |agent, i|
        agent.reindex(index)

        pct_complete = (i / count.to_f) * 100
        puts "Agent.reindex_all(): #{pct_complete.round(2)}%"
      end
      # Remove indexed documents whose entities have disappeared.
      # TODO: fix this
      #Agent.solr.all.limit(99999).select{ |a| a.to_s == a }.each do |agent_id|
      #  Solr.delete_by_id(agent_id)
      #end
    end
  end

  ##
  # N.B.: Changing this normally requires adding a new index schema version.
  #
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json(options = {})
    doc = {}
    doc[IndexFields::DESCRIPTION] = self.description.to_s
    doc[IndexFields::EFFECTIVELY_PUBLISHED] = true
    doc[IndexFields::LAST_INDEXED] = Time.now.utc.iso8601
    doc[IndexFields::NAME] = self.name.to_s
    doc[IndexFields::SEARCH_ALL] = [
        doc[IndexFields::NAME],
        doc[IndexFields::DESCRIPTION]
    ].join(' ')
    doc
  end

  ##
  # Assists in cross-entity search.
  #
  # @return [self]
  #
  def effective_representative_entity
    self
  end

  ##
  # @return [String]
  #
  def index_id
    "agent-#{self.id}"
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
  # @param index [Symbol] :current or :latest
  # @return [void]
  #
  def reindex(index = :current)
    index_in_elasticsearch(index)
  end

  ##
  # @return [Enumerable<Collection>]
  #
  def related_collections
    Collection.joins('LEFT JOIN entity_elements ON entity_elements.collection_id = collections.id').
        where('entity_elements.uri IN (?)', self.agent_uris.pluck(:uri))
  end

  ##
  # @return [Enumerable<Item>]
  #
  def related_objects
    Item.joins('LEFT JOIN entity_elements ON entity_elements.item_id = items.id').
        where('entity_elements.uri IN (?)', self.agent_uris.pluck(:uri)).
        where('variant IS NULL OR variant = ? OR variant IN (?)', '',
              [Item::Variants::DIRECTORY, Item::Variants::FILE])
  end

  ##
  # Alias of name().
  #
  # @return [String]
  #
  def title
    name
  end

  private

  def ascribe_default_uri
    if self.agent_uris.empty?
      self.agent_uris.build(uri: "urn:uuid:#{SecureRandom.uuid}", primary: true)
    end
  end

  def delete_from_elasticsearch
    logger = CustomLogger.instance
    begin
      logger.debug(['Deleting document... ',
                    __elasticsearch__.delete_document].join)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      logger.warn("Agent.delete_from_elasticsearch(): #{e}")
    end
  end

  ##
  # @param index [Symbol] :current or :latest
  # @return [void]
  #
  def index_in_elasticsearch(index = :current)
    ElasticsearchClient.instance.index_document(index, self.class, self.id,
                                                as_indexed_json)
  end

  def update_in_elasticsearch
    CustomLogger.instance.debug(['Updating document... ',
                                 __elasticsearch__.update_document ].join)
  end

end
