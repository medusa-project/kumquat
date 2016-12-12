class AgentUri < ActiveRecord::Base

  belongs_to :agent, inverse_of: :agent_uris

  validates_presence_of :uri

  def to_s
    "#{self.uri}"
  end

end
