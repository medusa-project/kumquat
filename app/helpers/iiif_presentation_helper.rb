module IiifPresentationHelper

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
