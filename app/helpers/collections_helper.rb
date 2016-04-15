module CollectionsHelper

  ##
  # @param collections [Relation]
  # @return [Array] Array of capitalized unique first characters of each
  #                 collection.
  #
  def collection_anchors(collections)
    anchors = []
    collections.each do |col|
      next unless effective_collection_access_url(col)
      normalized_title = col.title.downcase.gsub(/^a /, '').gsub(/^an /, '').
          gsub(/^the /, '')
      anchors << normalized_title[0].upcase
    end
    anchors.uniq
  end

  ##
  # @param collections [Relation]
  # @return [String]
  #
  def collections_as_list(collections)
    thumb_size = 140
    html = ''
    previous_first_letter = ''
    collections.each do |col|
      next unless effective_collection_access_url(col)

      bs = col.representative_image_bytestream
      if bs
        img_url = bytestream_image_url(bs, thumb_size)
      else
        img_url = image_url('folder-open-o-600.png')
      end

      # Sprinkle in some invisible IDed elements for the letter navigation
      # links to jump to.
      if col.title[0].upcase != previous_first_letter
        normalized_title = col.title.downcase.gsub(/^a /, '').gsub(/^an /, '').
            gsub(/^the /, '')
        previous_first_letter = normalized_title[0].upcase
        html += "<span id=\"#{previous_first_letter}\"></span>"
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
      html += truncate(col.description.to_s, length: 400)
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