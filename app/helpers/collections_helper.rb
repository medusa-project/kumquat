module CollectionsHelper

  ##
  # @param collections [Array]
  # @return [String]
  #
  def collections_as_list(collections)
    html = ''
    collections.each do |col|
      html += '<div class="media">'
      html += '<div class="media-left">'
      html += link_to(collection_url(col)) do
        image_tag(image_url(col.representative_item, 180),
                  class: 'media-object', alt: 'Collection thumbnail')
      end
      html += '</div>'
      html += '<div class="media-body">'
      html += '<h4 class="media-heading">'
      html += link_to(col.title, collection_url(col))
      html += '</h4>'
      html += truncate(col.description, length: 800)
      html += '</div>'
      html += '</div>'
    end
    raw(html)
  end

end