module IiifPresentationHelper

  MIN_CANVAS_SIZE = 1200

  ##
  # @param subitem [Item] Subitem or page
  #
  def iiif_canvas_for(subitem)
    case subitem.variant
      when Item::Variants::PAGE
        struct = {
            '@id': item_iiif_canvas_url(subitem, subitem.repository_id),
            '@type': 'sc:Canvas',
            'label': "Page #{subitem.page_number}",
            height: canvas_height(subitem),
            width: canvas_width(subitem),
            metadata: iiif_metadata_for(subitem)
        }
        struct[:images] = iiif_images_for(subitem, 'access') if subitem.is_image?
        return struct
      else
        struct = {
            '@id': item_iiif_canvas_url(subitem, subitem.repository_id),
            '@type': 'sc:Canvas',
            label: subitem.title,
            height: canvas_height(subitem),
            width: canvas_width(subitem),
            metadata: iiif_metadata_for(subitem)
        }
        struct[:images] = iiif_images_for(subitem, 'access') if subitem.is_image?
        return struct
    end
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_canvases_for(item)
    items = item.is_compound? ? item.pages : item.items
    items.map { |subitem| iiif_canvas_for(subitem) }
  end

  ##
  # @param item [Item]
  # @param annotation_name [String] 'access' or 'preservation'
  # @return [Array]
  #
  def iiif_images_for(item, annotation_name)
    [
        {
            '@type': 'oa:Annotation',
            '@id': item_iiif_annotation_url(item, annotation_name),
            motivation: 'sc:painting',
            resource: {
                '@id': iiif_image_url(item, 1000),
                '@type': 'dctypes:Image',
                'format': item.access_master_bytestream.media_type,
                service: {
                    '@context': 'http://iiif.io/api/image/2/context.json',
                    '@id': iiif_bytestream_url(item.access_master_bytestream),
                    profile: 'http://iiif.io/api/image/2/profiles/level2.json'
                },
                height: item.access_master_bytestream.height,
                width: item.access_master_bytestream.width
            },
            on: item_iiif_canvas_url(item, item.repository_id)
        }
    ]
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_metadata_for(item)
    elements = []
    item.collection.metadata_profile.elements.select(&:visible).each do |pe|
      item_elements = @item.elements.
          select{ |ie| ie.name == pe.name and ie.value.present? }
      if item_elements.any?
        elements << {
            label: pe.label,
            value: item_elements.length > 1 ?
                [ item_elements.map(&:value) ] : item_elements.first.value }
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
        label: variant.titleize,
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
    if item.pages.count > 0
      return [
          {
              '@id': item_iiif_sequence_url(item, :page),
              '@type': 'sc:Sequence',
              label: 'Pages',
              viewingHint: 'paged',
              canvases: iiif_canvases_for(item)
          }
      ]
    elsif item.items.count > 0
      return [
          {
             '@id': item_iiif_sequence_url(item, :item),
             '@type': 'sc:Sequence',
             label: 'Sub-Items',
             canvases: iiif_canvases_for(item)
          }
      ]
    end
  end

  private

  def canvas_height(item)
    height = item.access_master_bytestream&.height || MIN_CANVAS_SIZE
    height = MIN_CANVAS_SIZE if height < MIN_CANVAS_SIZE
    height
  end

  def canvas_width(item)
    width = item.access_master_bytestream&.width || MIN_CANVAS_SIZE
    width = MIN_CANVAS_SIZE if width < MIN_CANVAS_SIZE
    width
  end

end
