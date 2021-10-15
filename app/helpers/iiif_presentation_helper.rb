module IiifPresentationHelper

  DEFAULT_ANNOTATION_LIST_NAME = 'annotation1'
  DEFAULT_CANVAS_NAME          = 'canvas1'
  DEFAULT_LAYER_NAME           = 'layer1'
  DEFAULT_RANGE_NAME           = 'range1'
  LAYER_LABEL                  = 'Additional Content'
  MIN_CANVAS_SIZE              = 1200 # http://iiif.io/api/presentation/2.1/#canvas

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
      binary  = child.effective_image_binary
      dc_type = child.dc_type
      if (binary&.public? || current_user&.medusa_user?) && dc_type
        resources << {
            '@type':    'oa:Annotation',
            motivation: 'sc:painting',
            resource: {
                '@id':   item_url(child),
                # http://dublincore.org/documents/dcmi-type-vocabulary/#H7
                '@type': "dctypes:#{dc_type}",
                format:  binary.media_type
            },
            on: item_iiif_layer_url(item, list_name)
        }
      end
    end
    {
        '@context': 'http://iiif.io/api/presentation/2/context.json',
        '@id':      item_iiif_annotation_list_url(item, list_name),
        '@type':    'sc:AnnotationList',
        within: {
            '@id':   item_iiif_layer_url(item, DEFAULT_LAYER_NAME),
            '@type': 'sc:Layer',
            label:   LAYER_LABEL
        },
        resources: resources
    }
  end

  ##
  # @param subitem [Item] Subitem or page
  # @param include_metadata [Boolean]
  # @return [Hash<Symbol,Object>]
  #
  def iiif_canvas_for(subitem, include_metadata:)
    struct = {
        '@id':   item_iiif_canvas_url(subitem, DEFAULT_CANVAS_NAME),
        '@type': 'sc:Canvas',
        label:   subitem.title,
        height:  canvas_height(subitem),
        width:   canvas_width(subitem)
    }
    if include_metadata
      struct[:metadata] = iiif_metadata_for(subitem)
    end
    binary = subitem.effective_image_binary
    if binary&.public? || current_user&.medusa_user?
      struct[:images] = iiif_image_resources_for(subitem, 'access')
    end
    struct
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_canvases_for(item)
    # Directory and 3D items are not viewable, and composite and supplement
    # items are included in the annotation list instead.
    exclude_variants = [Item::Variants::COMPOSITE,
                        Item::Variants::DIRECTORY,
                        Item::Variants::SUPPLEMENT,
                        Item::Variants::THREE_D_MODEL]
    result = item.search_children.
        include_restricted(true).
        include_unpublished(false).
        exclude_variants(*exclude_variants).to_a
    if result.count > 0
      canvases = result.map { |child| iiif_canvas_for(child, include_metadata: true) }
    else
      canvases = [ iiif_canvas_for(item, include_metadata: !(item.file? || item.directory?)) ]
    end
    canvases
  end

  ##
  # @param collections [Enumerable<Collection>]
  #
  def iiif_collection_list_for(collections)
    collections.map do |c|
      {
          '@id':   collection_iiif_presentation_url(c),
          '@type': 'sc:Collection',
          label:   c.title
      }
    end
  end

  ##
  # @param item [Item]
  # @param resource_name [String]
  # @return [Array]
  #
  def iiif_image_resources_for(item, resource_name)
    images = []
    binary = item.effective_image_binary
    if binary&.public? || current_user&.medusa_user?
      images << {
          '@type':    'oa:Annotation',
          '@id':      item_iiif_image_resource_url(item, resource_name),
          motivation: 'sc:painting',
          resource: {
              '@id':    item_image_url(item: item, size: 1000),
              '@type':  'dctypes:Image',
              'format': binary.media_type,
              service: {
                  '@context': 'http://iiif.io/api/image/2/context.json',
                  '@id':      binary.iiif_image_v2_url,
                  profile:    'http://iiif.io/api/image/2/profiles/level2.json'
              },
              height: binary.height,
              width:  binary.width
          },
          on: item_iiif_canvas_url(item, DEFAULT_CANVAS_NAME)
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
        '@id':      item_iiif_layer_url(item, layer_name),
        '@type':    'sc:Layer',
        label:      LAYER_LABEL
    }

    items = item.items.where('variant IN (?)', [Item::Variants::COMPOSITE,
                                                Item::Variants::SUPPLEMENT])
    if items.any?
      struct[:otherContent] = items.map do |it|
        item_iiif_annotation_list_url(item, DEFAULT_ANNOTATION_LIST_NAME)
      end
    end
    struct
  end

  ##
  # Media sequences are a Wellcome Library extension to the IIIF Presentation
  # API that enable the UniversalViewer to display non-image content.
  #
  # See: https://gist.github.com/tomcrane/7f86ac08d3b009c8af7c
  #
  # @param item [Item]
  # @return [Array]
  #
  def iiif_media_sequences_for(item)
    sequences = []
    item.items.each do |child|
      # Audio
      # Example: http://wellcomelibrary.org/iiif/b17307922/manifest
      child.binaries.
          select{ |b| (binary&.public? || current_user&.medusa_user?) &&
              b.media_category == Binary::MediaCategory::AUDIO &&
              b.master_type == Binary::MasterType::ACCESS }.each do |bin|
        sequences << {
            '@id':   item_iiif_media_sequence_url(item, bin.filename),
            '@type': 'ixif:MediaSequence',
            'label': "XSequence #{bin.filename}",
            'elements': [
                '@id':       binary_url(bin),
                '@type':     "dctypes:#{bin.dc_type}",
                'format':    bin.media_type,
                'label':     child.title,
                'metadata':  iiif_metadata_for(child),
                'thumbnail': ImageServer.image_v2_url(child.effective_image_binary,
                                                      size: ItemsHelper::DEFAULT_THUMBNAIL_SIZE),
                rendering: {
                    '@id':  binary_url(bin),
                    format: bin.media_type
                }
            ]
        }
      end
    end
    sequences
  end

  ##
  # @param item [Item]
  # @return [Array<Hash>]
  #
  def iiif_metadata_for(item)
    elements = []
    item.collection.metadata_profile.elements.select(&:visible).each do |pe|
      item_elements = item.elements.select{ |ie| ie.name == pe.name && ie.value.present? }
      if item_elements.any?
        elements << {
            label: pe.label,
            value: item_elements.length > 1 ?
                item_elements.pluck(:value) : item_elements.first.value
        }
      end
    end
    elements
  end

  ##
  # @param item [Item] Compound object
  # @param subitem [Item] Item
  # @return [Hash]
  #
  def iiif_range_for(item, subitem)
    struct = {
        '@id': item_iiif_range_url(item, DEFAULT_RANGE_NAME),
        '@type': 'sc:Range',
        label: subitem.title
    }
    if [Item::Variants::COMPOSITE, Item::Variants::SUPPLEMENT].include?(subitem.variant)
      struct[:contentLayer] = item_iiif_layer_url(item, DEFAULT_RANGE_NAME)
    else
      struct[:canvases] = [ item_iiif_canvas_url(subitem, DEFAULT_CANVAS_NAME) ]
    end
    struct
  end

  ##
  # @param item [Item]
  # @return [Array]
  # @see http://iiif.io/api/presentation/2.1/#range
  #
  def iiif_ranges_for(item)
    ranges = item.items.where('variant NOT IN (?)', [Item::Variants::PAGE]).map do |subitem|
      iiif_range_for(item, subitem)
    end

    top_range = ranges.find{ |r| r[:label] == Item::Variants::TITLE.titleize } ||
        ranges.find{ |r| r[:label] == Item::Variants::TABLE_OF_CONTENTS.titleize }
    top_range[:viewingHint] = 'top' if top_range

    ranges
  end

  ##
  # N.B.: this method does not consider whether the given item is actually
  # searchable (i.e. has full text). See {Item#has_full_text?}.
  #
  # @param item [Item]
  # @return [Hash]
  # @see https://iiif.io/api/search/0.9/#service-description
  #
  def iiif_search_service_description(item)
    {
      '@context': 'http://iiif.io/api/search/0/context.json',
      '@id':      item_iiif_search_url(item),
      profile:    'http://iiif.io/api/search/0/search'
      #service: {
      #  '@id':   item_iiif_search_autocomplete_url(item),
      #  profile: 'http://iiif.io/api/search/0/autocomplete',
      #}
    }
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
              '@id':       item_iiif_sequence_url(item, :page),
              '@type':     'sc:Sequence',
              label:       'Pages',
              viewingHint: 'paged',
              canvases:    iiif_canvases_for(item)
          }
      ]
    # Otherwise, if it has any items of any variant, they will comprise the
    # sequences.
    elsif item.items.count > 0
      sequences = [
          {
             '@id':    item_iiif_sequence_url(item, :item),
             '@type':  'sc:Sequence',
             label:    'Sub-Items',
             canvases: iiif_canvases_for(item)
          }
      ]
    # Otherwise, the item itself will comprise its sequence.
    else
      sequences = [
          {
              '@id':    item_iiif_sequence_url(item, :item),
              '@type':  'sc:Sequence',
              label:    item.title,
              canvases: iiif_canvases_for(item)
          }
      ]
    end
    sequences
  end

  private

  def canvas_height(item)
    # "It is recommended that if there is (at the time of implementation) a
    # single image that depicts the page, then the dimensions of the image are
    # used as the dimensions of the canvas for simplicity. If there are
    # multiple full images, then the dimensions of the largest image should be
    # used. If the largest image’s dimensions are less than 1200 pixels on
    # either edge, then the canvas’s dimensions should be double those of the
    # image."
    height = MIN_CANVAS_SIZE
    item.binaries.select{ |b| b.public? || current_user&.medusa_user? }.each do |b|
      height = b.height if b.height && b.height > height
    end
    height
  end

  def canvas_width(item)
    width = MIN_CANVAS_SIZE
    item.binaries.select{ |b| b.public? || current_user&.medusa_user? }.each do |b|
      width = b.width if b.width && b.width > width
    end
    width
  end

end
