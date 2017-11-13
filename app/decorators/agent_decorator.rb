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
        class: Agent.to_s,
        id: object.id,
        name: object.name,
        description: object.description,
        uris: object.agent_uris.pluck(:uri),
        agent_relations: context[:agent_relations].map{ |r|
          {
              subject: {
                  name: r.agent.name,
                  uri: agent_url(r.agent)
              },
              relationship: {
                  name: r.agent_relation_type&.name,
                  uri: r.agent_relation_type&.uri
              },
              object: {
                  name: r.related_agent.name,
                  uri: agent_url(r.related_agent)
              }
          }
        },
        related_collections: context[:related_collections].map{ |c| collection_url(c) },
        related_objects: context[:related_objects].map{ |o| item_url(o) }
    }
  end

end
