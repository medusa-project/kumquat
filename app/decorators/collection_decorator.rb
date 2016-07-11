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
        representative_image: self.representative_image,
        representative_item: self.representative_item ?
            item_url(self.representative_item) : nil,
        repository_title: self.repository_title,
        resource_types: self.resource_types
    }
  end

end
