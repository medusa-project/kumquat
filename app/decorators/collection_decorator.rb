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
        id: self.repository_id,
        title: self.title,
        description: self.description,
        description_html: self.description_html,
        access_url: self.access_url,
        physical_collection_url: self.physical_collection_url,
        representative_image: self.representative_image,
        representative_item: self.representative_item ?
            item_url(self.representative_item) : nil,
        repository_title: self.medusa_repository.title,
        resource_types: self.resource_types,
        access_systems: self.access_systems,
        rights_statement: self.rightsstatements_org_uri
    }
  end

end
