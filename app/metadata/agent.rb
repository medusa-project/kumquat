class Agent < ActiveRecord::Base

  belongs_to :agent_rule, inverse_of: :agents

  has_many :agent_relations, class_name: 'AgentRelation',
           foreign_key: :agent_id, dependent: :destroy
  has_many :related_agents, -> { order('name ASC') },
           through: :agent_relations, source: :related_agent

  before_validation :ascribe_default_uri, if: :new_record?

  validates_presence_of :name, :uri

  private

  def ascribe_default_uri
    self.uri = "urn:uuid:#{SecureRandom.uuid}" if self.uri.blank?
  end

end
