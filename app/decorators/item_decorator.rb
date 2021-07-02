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
    struct = {
        class:                   Item.to_s,
        id:                      object.repository_id,
        public_uri:              item_url(self),
        parent_uri:              object.parent ?
                                     item_url(object.parent, format: :json) : nil,
        collection_uri:          object.collection ?
                                     collection_url(object.collection, format: :json) : nil,
        iiif_manifest_uri:       nil, # filled in below
        page_number:             object.page_number,
        subpage_number:          object.subpage_number,
        normalized_start_date:   object.start_date,
        normalized_end_date:     object.end_date,
        normalized_latitude:     object.latitude&.to_f,
        normalized_longitude:    object.longitude&.to_f,
        variant:                 object.variant,
        representative_item_uri: object.representative_item ?
                                     item_url(object.representative_item, format: :json) : nil,
        representative_images:   {},
        full_text:               object.full_text,
        elements:                object.elements_in_profile_order(only_visible: true).map(&:decorate),
        binaries:                object.binaries.map{ |b| binary_url(b) },
        children:                object.items.map{ |i| item_url(i, format: :json) },
        created_at:              object.created_at,
        published_at:            object.published_at,
        updated_at:              object.updated_at,
    }

    manifest_item = object
    unless manifest_item.has_iiif_manifest?
      manifest_item = object.parent || object
    end
    struct[:iiif_manifest_uri] = item_iiif_manifest_url(manifest_item)

    bin = object.effective_image_binary
    if bin
      struct[:representative_images][:full] = { full: binary_url(bin) }
      if bin.image_server_safe?
        min_exp = 6
        max_exp = 12
        (min_exp..max_exp).each do |exp|
          size = 2 ** exp
          if (bin.width && bin.width >= size) || (bin.height && bin.height >= size)
            struct[:representative_images][:full][size.to_s] =
                "#{bin.iiif_image_url}/full/!#{size},#{size}/0/default.jpg"
          end
        end

        struct[:representative_images][:square] = {}
        (min_exp..max_exp).each do |exp|
          size = 2 ** exp
          if bin.width && bin.width >= size && bin.height && bin.height >= size
            struct[:representative_images][:square][size.to_s] =
                "#{bin.iiif_image_url}/square/!#{size},#{size}/0/default.jpg"
          end
        end
      end
    end
    struct
  end

end
