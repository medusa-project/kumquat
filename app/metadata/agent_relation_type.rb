class AgentRelationType < ApplicationRecord

  has_many :agent_relations, inverse_of: :agent_relation_type

  validates_presence_of :name, :uri

end
