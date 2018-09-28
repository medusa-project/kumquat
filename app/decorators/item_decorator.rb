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
        # Convenience key for Metaslurper
        representative_images: object.effective_image_binary ? {
            full: {
                '128': "#{object.effective_image_binary.iiif_image_url}/full/!128,128/0/default.jpg",
                '256': "#{object.effective_image_binary.iiif_image_url}/full/!256,256/0/default.jpg",
                '512': "#{object.effective_image_binary.iiif_image_url}/full/!512,512/0/default.jpg",
                '1024': "#{object.effective_image_binary.iiif_image_url}/full/!1024,1024/0/default.jpg",
                '2048': "#{object.effective_image_binary.iiif_image_url}/full/!2048,2048/0/default.jpg"
            },
            square: {
                '128': "#{object.effective_image_binary.iiif_image_url}/square/!128,128/0/default.jpg",
                '256': "#{object.effective_image_binary.iiif_image_url}/square/!256,256/0/default.jpg",
                '512': "#{object.effective_image_binary.iiif_image_url}/square/!512,512/0/default.jpg",
                '1024': "#{object.effective_image_binary.iiif_image_url}/square/!1024,1024/0/default.jpg",
                '2048': "#{object.effective_image_binary.iiif_image_url}/square/!2048,2048/0/default.jpg"
            }
        } : {},
        # Convenience key for Metaslurper
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
