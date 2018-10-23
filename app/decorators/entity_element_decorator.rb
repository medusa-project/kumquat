##
# Assists in creating an optimized JSON serialization.
#
class EntityElementDecorator < Draper::Decorator
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
    if object.respond_to?(:item)
      profile = object.item.collection.metadata_profile
    else
      profile = object.collection.metadata_profile
    end
    struct = {
        name: object.name,
        value: object.value.present? ? object.value : nil,
        uri: object.uri.present? ? object.uri : nil,
        vocabulary: object.vocabulary&.name,

    }
    if profile
      profile_element = profile.elements.select{ |ed| ed.name == object.name }.first
      struct[:mappings] = {
          dc: profile_element&.dc_map.present? ? profile_element.dc_map : nil,
          dcterms: profile_element&.dcterms_map.present? ? profile_element.dcterms_map : nil
      }
    end
    struct
  end

end
