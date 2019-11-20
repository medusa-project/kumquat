##
# Some kind of noun supporting many-to-many relationships to other agents/
# nouns.
#
class Agent < ApplicationRecord

  include Representable

  class IndexFields
    CLASS                        = ElasticsearchIndex::StandardFields::CLASS
    DESCRIPTION                  = 'sys_t_description'
    EFFECTIVE_ALLOWED_ROLE_COUNT = 'sys_i_effective_allowed_role_count'
    EFFECTIVE_ALLOWED_ROLES      = 'sys_k_effective_allowed_roles'
    EFFECTIVE_DENIED_ROLE_COUNT  = 'sys_i_effective_denied_role_count'
    EFFECTIVE_DENIED_ROLES       = 'sys_k_effective_denied_roles'
    LAST_INDEXED                 = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED                = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    NAME                         = 'sys_t_name'
    PUBLICLY_ACCESSIBLE          = ElasticsearchIndex::StandardFields::PUBLICLY_ACCESSIBLE
    SEARCH_ALL                   = ElasticsearchIndex::StandardFields::SEARCH_ALL
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

  def self.delete_orphaned_documents
    # TODO: write this
  end

  ##
  # @param id [String]
  # @return [Agent]
  #
  def self.find_by_repository_id(id)
    # This logic must be kept in sync with that of index_id().
    Agent.find(id.gsub(/[^0-9]/, ''))
  end

  ##
  # N.B.: Orphaned documents are not deleted; for that, use
  # {delete_orphaned_documents}.
  #
  # @param index [String] Index name. If omitted, the default index is used.
  # @return [void]
  #
  def self.reindex_all(index = nil)
    count = Agent.count
    start_time = Time.now
    Agent.uncached do
      Agent.all.find_each.with_index do |agent, i|
        agent.reindex(index)
        StringUtils.print_progress(start_time, i, count, 'Indexing agents')
      end
    end
  end

  ##
  # N.B.: Changing this normally requires adding a new index schema version.
  #
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json(options = {})
    doc = {}
    doc[IndexFields::CLASS] = self.class.to_s
    doc[IndexFields::DESCRIPTION] = self.description.to_s
    doc[IndexFields::EFFECTIVE_ALLOWED_ROLES] = []
    doc[IndexFields::EFFECTIVE_ALLOWED_ROLE_COUNT] = 0
    doc[IndexFields::EFFECTIVE_DENIED_ROLES] = []
    doc[IndexFields::EFFECTIVE_DENIED_ROLE_COUNT] = 0
    doc[IndexFields::LAST_INDEXED] = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED] = self.updated_at.utc.iso8601
    doc[IndexFields::NAME] = self.name.to_s
    doc[IndexFields::PUBLICLY_ACCESSIBLE] = true
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

  def effective_representative_image_binary
    nil
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
  # @param index [String] Index name. If omitted, the default index is used.
  # @return [void]
  #
  def reindex(index = nil)
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
  # Alias of id.
  #
  def repository_id
    id
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
    query = {
        query: {
            bool: {
                filter: [
                    {
                        term: {
                            '_id': self.id
                        }
                    }
                ]
            }
        }
    }
    ElasticsearchClient.instance.delete_by_query(JSON.generate(query))
  end

  ##
  # @param index [String] Index name. If omitted, the default index is used.
  # @return [void]
  #
  def index_in_elasticsearch(index)
    index ||= Configuration.instance.elasticsearch_index
    ElasticsearchClient.instance.index_document(index,
                                                self.repository_id,
                                                self.as_indexed_json)
  end

end
