module CollectionsHelper

  ##
  # @param collections [Array]
  # @return [String]
  #
  def collections_as_list(collections)
    thumb_size = 140
    html = ''
    collections.each do |col|
      next unless effective_collection_access_url(col)
      if col.representative_item
        img_url = item_image_url(col.representative_item, thumb_size)
      else
        img_url = image_url('folder-open-o-600.png')
      end
      html += '<div class="media">'
      html += '<div class="media-left">'
      html += link_to(collection_url(col)) do
        image_tag(img_url, class: 'media-object', alt: 'Collection thumbnail',
                  style: "width: #{thumb_size}px")
      end
      html += '</div>'
      html += '<div class="media-body">'
      html += '<h4 class="media-heading">'
      html += link_to(col.title, collection_url(col))
      html += '</h4>'
      html += truncate(col.description, length: 400)
      html += '</div>'
      html += '</div>'
    end
    raw(html)
  end

  def effective_collection_access_url(collection)
    if collection.published_in_dls
      return collection_items_path(collection)
    elsif collection.published and collection.access_url and
        collection.access_url.length > 0
      return collection.access_url
    end
    nil
  end

end