class AgentRelation < ApplicationRecord

  belongs_to :agent, class_name: 'Agent'
  belongs_to :related_agent, class_name: 'Agent', foreign_key: :related_agent_id
  belongs_to :agent_relation_type, inverse_of: :agent_relations

  validates_each :related_agent_id do |record, attr, value|
    record.errors.add attr, 'Agent cannot be related to itself' if
        value == record.agent
  end

  ##
  # @param agent [Agent]
  # @return [Enumerable<Agent>] All AgentRelations related to the given agent.
  #
  def self.related_to_agent(agent)
    AgentRelation.where('agent_id = ? OR related_agent_id = ?',
                        agent.id, agent.id)
  end

end
