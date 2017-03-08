module IiifPresentationHelper

  LAYER_LABEL = 'Additional Content'
  MIN_CANVAS_SIZE = 1200 # http://iiif.io/api/presentation/2.1/#canvas

  ##
  # @param item [Item] Compound object.
  # @param list_name [String] Should be the same as the name of the canvas
  #                           that the annotation list is ascribed to.
  # @see http://iiif.io/api/presentation/2.1/#annotation-list
  #
  def iiif_annotation_list_for(item, list_name)
    resources = []
    item.items.where('variant IN (?)', [Item::Variants::COMPOSITE,
                                        Item::Variants::SUPPLEMENT]).each do |child|
      binary = child.access_master_binary || child.preservation_master_binary
      dc_type = child.dc_type
      if binary and dc_type
      resources << {
          '@type': 'oa:Annotation',
          motivation: 'sc:painting',
          resource: {
              '@id': item_url(child),
              # http://dublincore.org/documents/dcmi-type-vocabulary/#H7
              '@type': "dctypes:#{dc_type}",
              format: binary.media_type
          },
          on: item_iiif_layer_url(item, list_name)
      }
      end
    end

    {
        '@context': 'http://iiif.io/api/presentation/2/context.json',
        '@id': item_iiif_annotation_list_url(item, list_name),
        '@type': 'sc:AnnotationList',
        within: {
            '@id': item_iiif_layer_url(item, item.repository_id),
            '@type': 'sc:Layer',
            label: LAYER_LABEL
        },
        resources: resources
    }
  end

  ##
  # @param subitem [Item] Subitem or page
  # @return [Hash<Symbol,Object>]
  #
  def iiif_canvas_for(subitem)
    struct = {
        '@id': item_iiif_canvas_url(subitem, subitem.repository_id),
        '@type': 'sc:Canvas',
        label: subitem.title,
        height: canvas_height(subitem),
        width: canvas_width(subitem),
        metadata: iiif_metadata_for(subitem)
    }
    if subitem.is_image? or subitem.is_pdf?
      struct[:images] = iiif_images_for(subitem, 'access')
    end
    struct
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_canvases_for(item)
    items = item.items_in_iiif_presentation_order.to_a
    if items.any?
      # Composite and supplement items are included in the annotation list
      # instead.
      return items.select{ |it| ![Item::Variants::COMPOSITE,
                                  Item::Variants::SUPPLEMENT].include?(it.variant) }.
          map { |subitem| iiif_canvas_for(subitem) }
    end
    [ iiif_canvas_for(item) ]
  end

  ##
  # @param item [Item]
  # @param annotation_name [String] 'access' or 'preservation'
  # @return [Array]
  #
  def iiif_images_for(item, annotation_name)
    images = []
    bin = item.access_master_binary || item.preservation_master_binary
    if bin
      images << {
          '@type': 'oa:Annotation',
          '@id': item_iiif_annotation_url(item, annotation_name),
          motivation: 'sc:painting',
          resource: {
              '@id': iiif_image_url(item, 1000),
              '@type': 'dctypes:Image',
              'format': bin.media_type,
              service: {
                  '@context': 'http://iiif.io/api/image/2/context.json',
                  '@id': bin.iiif_image_url,
                  profile: 'http://iiif.io/api/image/2/profiles/level2.json'
              },
              height: bin.height,
              width: bin.width
          },
          on: item_iiif_canvas_url(item, item.repository_id)
      }
    end
    images
  end

  ##
  # @param item [Item] Compound object.
  # @param layer_name [String] Should be the same as the name of the canvas
  #                            that the layer is ascribed to.
  # @see http://iiif.io/api/presentation/2.1/#layer
  #
  def iiif_layer_for(item, layer_name)
    struct = {
        '@context': 'http://iiif.io/api/presentation/2/context.json',
        '@id': item_iiif_layer_url(item, layer_name),
        '@type': 'sc:Layer',
        label: LAYER_LABEL
    }

    items = item.items.where('variant IN (?)', [Item::Variants::COMPOSITE,
                                                Item::Variants::SUPPLEMENT])
    if items.any?
      struct[:otherContent] = items.map do |it|
        item_iiif_annotation_list_url(item, it.repository_id)
      end
    end
    struct
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_media_sequences_for(item)
    sequences = nil
    if item.variant == Item::Variants::FILE and item.is_pdf?
      sequences = [
          {
              '@id': item_iiif_media_sequence_url(item, :page),
              '@type': 'ixif:MediaSequence',
              label: 'XSequence 0',
              elements: [
                  '@id': item_access_master_binary_url(item),
                  '@type': 'foaf:Document',
                  format: item.access_master_binary.media_type,
                  label: item.title,
                  metadata: [],
                  thumbnail: thumbnail_url(item)
              ]
          }
      ]
    end
    sequences
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_metadata_for(item)
    elements = []
    item.collection.metadata_profile.elements.select(&:visible).each do |pe|
      item_elements = item.elements.
          select{ |ie| ie.name == pe.name and ie.value.present? }
      if item_elements.any?
        elements << {
            label: pe.label,
            value: item_elements.length > 1 ?
                item_elements.map(&:value) : item_elements.first.value
        }
      end
    end
    elements
  end

  ##
  # @param item [Item] Compound object
  # @param variant [String] One of the Item::Variants constant values
  # @return [Hash]
  #
  def iiif_range_for(item, variant)
    subitem = item.items.where(variant: variant).first
    {
        '@id': item_iiif_range_url(item, variant),
        '@type': 'sc:Range',
        label: subitem.title,
        canvases: [ item_iiif_canvas_url(subitem, subitem.repository_id) ]
    }
  end

  ##
  # @param item [Item]
  # @return [Array]
  # @see http://iiif.io/api/presentation/2.1/#range
  #
  def iiif_ranges_for(item)
    ranges = item.items.where('variant NOT IN (?)', [Item::Variants::PAGE]).map do |subitem|
      iiif_range_for(item, subitem.variant)
    end

    top_range = ranges.select{ |r| r[:label] == Item::Variants::TITLE.titleize }.first ||
        ranges.select{ |r| r[:label] == Item::Variants::TABLE_OF_CONTENTS.titleize }.first
    top_range[:viewingHint] = 'top' if top_range

    ranges
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_sequences_for(item)
    # If the item has any pages, they will comprise the sequences.
    if item.pages.count > 0
      sequences = [
          {
              '@id': item_iiif_sequence_url(item, :page),
              '@type': 'sc:Sequence',
              label: 'Pages',
              viewingHint: 'paged',
              canvases: iiif_canvases_for(item)
          }
      ]
    # Otherwise, if it has any items of any variant, they will comprise the
    # sequences.
    elsif item.items.count > 0
      sequences = [
          {
             '@id': item_iiif_sequence_url(item, :item),
             '@type': 'sc:Sequence',
             label: 'Sub-Items',
             canvases: iiif_canvases_for(item)
          }
      ]
    # Otherwise, the item itself will comprise its sequence.
    else
      sequences = [
          {
              '@id': item_iiif_sequence_url(item, :item),
              '@type': 'sc:Sequence',
              label: item.title,
              canvases: iiif_canvases_for(item)
          }
      ]
    end
    sequences
  end

  private

  def canvas_height(item)
    bin = item.access_master_binary || item.preservation_master_binary
    height = bin&.height || MIN_CANVAS_SIZE
    height = MIN_CANVAS_SIZE if height < MIN_CANVAS_SIZE
    height
  end

  def canvas_width(item)
    bin = item.access_master_binary || item.preservation_master_binary
    width = bin&.width || MIN_CANVAS_SIZE
    width = MIN_CANVAS_SIZE if width < MIN_CANVAS_SIZE
    width
  end

end
