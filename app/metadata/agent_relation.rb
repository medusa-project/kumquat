class AgentRelation < ActiveRecord::Base

  belongs_to :agent, class_name: 'Agent'
  belongs_to :related_agent, class_name: 'Agent', foreign_key: :related_agent_id

  validates_each :related_agent_id do |record, attr, value|
    record.errors.add attr, 'Agent cannot be related to itself' if
        value == record.agent
  end

end
