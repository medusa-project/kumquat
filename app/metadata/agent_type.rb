class AgentType < ApplicationRecord

  has_many :agents, inverse_of: :agent_types

  validates_presence_of :name

end
