module IiifPresentationHelper

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_canvases(item)
    item.pages.map do |page|
      {
          '@id': item_iiif_canvas_url(page, page.repository_id),
          '@type': 'sc:Canvas',
          'label': "Page #{item.page_number}"
      }
    end
  end

  ##
  # @param collection [Collection]
  # @return [Array]
  #
  def iiif_manifests_for(collection)
    collection.items.map do |item| # top-level items only
      {
          '@id': item_iiif_manifest_url(item),
          '@type': 'sc:Manifest',
          label: item.title
      }
    end
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

end
