##
# Assists in creating an optimized JSON serialization.
#
# Examples:
#
# * Generate a web-ready representation
#     Item.find(..).decorate
#
# * Generate a non-web representation
#     Item.find(..).decorate(context: { web: false })
#
class ItemDecorator < Draper::Decorator
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
        class: Item.to_s,
        id: object.repository_id,
        public_uri: item_url(self),
        parent_uri: object.parent ? item_url(object.parent, format: :json) : nil,
        collection_uri: object.collection ?
                        collection_url(object.collection, format: :json) : nil,
        page_number: object.page_number,
        subpage_number: object.subpage_number,
        normalized_date: object.date,
        normalized_latitude: object.latitude&.to_f,
        normalized_longitude: object.longitude&.to_f,
        variant: object.variant,
        representative_item_uri: object.representative_item ?
            item_url(object.representative_item, format: :json) : nil,
        # Convenience key for Metaslurp
        effective_representative_image_uri: object.effective_image_binary ?
            binary_url(object.effective_image_binary) : nil,
        # Convenience key for Metaslurp
        preservation_media_type: object.binaries.
            where(master_type: Binary::MasterType::PRESERVATION).limit(1).first&.media_type,
        elements: object.elements_in_profile_order(only_visible: true).map(&:decorate),
        binaries: object.binaries.map{ |b| binary_url(b, format: :json) },
        children: object.items.map{ |i| item_url(i, format: :json) },
        created_at: object.created_at,
        updated_at: object.updated_at,
    }
  end

end
