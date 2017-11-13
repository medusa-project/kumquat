##
# Assists in creating an optimized JSON serialization.
#
class CollectionDecorator < Draper::Decorator
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
        class: Collection.to_s,
        id: object.repository_id,
        public_uri: collection_url(object),
        access_uri: object.access_url,
        physical_collection_uri: object.physical_collection_url,
        representative_image_uri: binary_url(object.representative_image, format: :json),
        representative_item_uri: object.representative_item ?
            item_url(object.representative_item, format: :json) : nil,
        repository_title: object.medusa_repository.title,
        resource_types: object.resource_types,
        access_systems: object.access_systems,
        rights_statement: object.rightsstatements_org_uri,
        elements: object.elements_in_profile_order(only_visible: true).map(&:decorate),
        created_at: object.created_at,
        updated_at: object.updated_at
    }
  end

end
