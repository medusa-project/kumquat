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
    struct = {
        id: self.repository_id,
        public_uri: collection_url(self),
        access_uri: self.access_url,
        physical_collection_uri: self.physical_collection_url,
        representative_image_uri: binary_url(self.representative_image, format: :json),
        representative_item_uri: self.representative_item ?
            item_url(self.representative_item, format: :json) : nil,
        repository_title: self.medusa_repository.title,
        resource_types: self.resource_types,
        access_systems: self.access_systems,
        rights_statement: self.rightsstatements_org_uri,
        elements: self.elements_in_profile_order(only_visible: true).map(&:decorate),
        created_at: self.created_at,
        updated_at: self.updated_at
    }

    struct
  end

end
