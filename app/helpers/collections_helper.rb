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