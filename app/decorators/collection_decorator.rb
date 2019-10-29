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
    parent = object.parents.first
    parent = parent ? { id: parent.repository_id,
                        uri: collection_url(parent) } : nil

    struct = {
        class:                   Collection.to_s,
        id:                      object.repository_id,
        external_id:             object.external_id,
        public_uri:              collection_url(object),
        access_uri:              object.access_url,
        physical_collection_uri: object.physical_collection_url,
        repository_title:        object.medusa_repository.title,
        resource_types:          object.resource_types,
        access_systems:          object.access_systems,
        rights_statement:        object.rightsstatements_org_uri,
        package_profile:         object.package_profile&.name,
        representative_images:   {},
        representative_item_uri: object.representative_item ?
                                     item_url(object.representative_item, format: :json) : nil,
        elements:                object.elements_in_profile_order(only_visible: true).map(&:decorate),
        parent:                  parent,
        children:                object.children.map{ |c| { id: c.repository_id,
                                                            uri: collection_url(c) } },
        created_at:              object.created_at,
        updated_at:              object.updated_at
    }

    bin = object.effective_representative_image_binary
    if bin
      struct[:representative_images][:full] = { full: binary_url(bin, format: :json) }
      if bin.image_server_safe?
        min_exp = 6
        max_exp = 12
        (min_exp..max_exp).each do |exp|
          size = 2 ** exp
          if (bin.width and bin.width >= size) or (bin.height and bin.height >= size)
            struct[:representative_images][:full][size.to_s] =
                "#{bin.iiif_image_url}/full/!#{size},#{size}/0/default.jpg"
          end
        end

        struct[:representative_images][:square] = {}
        (min_exp..max_exp).each do |exp|
          size = 2 ** exp
          if bin.width and bin.width >= size and bin.height and bin.height >= size
            struct[:representative_images][:square][size.to_s] =
                "#{bin.iiif_image_url}/square/!#{size},#{size}/0/default.jpg"
          end
        end
      end
    end
    struct
  end

end
