class AgentRule < ApplicationRecord

  has_many :agents, inverse_of: :agent_rules

  validates_presence_of :name

end
