##
# Assists in creating an optimized JSON serialization.
#
class AgentDecorator < Draper::Decorator
  delegate_all
  include Draper::LazyHelpers

  # Define presentation-specific methods here. Helpers are accessed through
  # `helpers` (aka `h`). You can override attributes, for example:
  #
  #   def created_at
  #     helpers.content_tag :span, class: 'time' do
  #       object.created_at.strftime("%a %m/%d/%y")
  #     end
  #   end

  def serializable_hash(opts)
    {
        name: self.name,
        description: self.description,
        uris: self.agent_uris.map(&:uri),
        related_agents: context[:related_agents].map{ |o| { url: agent_url(o) } },
        related_collections: context[:related_collections].map{ |o| { url: collection_url(o) } },
        related_objects: context[:related_objects].map{ |o| { url: item_url(o) } }
    }
  end

end
