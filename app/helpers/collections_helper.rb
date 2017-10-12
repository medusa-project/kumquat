module CollectionsHelper

  ##
  # @param collection [Collection]
  # @return [String] HTML string
  #
  def collection_page_title(collection)
    html = ''
    num_parents = collection.parents.count
    if num_parents > 0
      relative_parent = collection.parents.first
      html += '<h1 class="pt-title pt-compound-title">'
      html += "<small>#{link_to relative_parent.title, relative_parent}</small>"
      html += "<br>&nbsp;&nbsp;&#8627; "
      html += "#{collection.title}</h1>"
    else
      html += "<h1 class=\"pt-title\">#{collection.title}</h1>"
    end
    raw(html)
  end

  def collections_as_cards(collections)
    thumb_size = 500
    html = ''
    collections.each do |col|
      bs = nil
      if Option::string(Option::Keys::SERVER_STATUS) != 'storage_offline'
        begin
          # If the reference to the binary is invalid (for example, an invalid
          # UUID has been entered), this will raise an error.
          bs = col.effective_representative_image_binary
        rescue => e
          CustomLogger.instance.warn("collections_as_cards(): #{e} (#{col})")
        end
      end
      if bs
        img_url = binary_image_url(bs, thumb_size, :square)
      else
        img_url = image_url('folder-open-o-600.png')
      end
      html += '<div class="pt-card">'
      html += '  <div class="pt-card-content">'
      html +=      link_to(col) do
                     raw("<img src=\"#{img_url}\">")
                   end
      html += '    <h4 class="pt-title">'
      html +=        link_to(col.title, col)
      html += '    </h4>'
      html += '  </div>'
      html += '</div>'
    end
    raw(html)
  end

  def effective_collection_access_url(collection)
    if collection.published_in_dls
      return collection_items_path(collection)
    elsif collection.public_in_medusa and collection.access_url and
        collection.access_url.length > 0
      return collection.access_url
    end
    nil
  end

end