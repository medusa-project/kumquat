module CollectionsHelper

  ##
  # @param collection [Collection]
  # @return [String] HTML string
  #
  def collection_page_title(collection)
    html = StringIO.new
    num_parents = collection.parents.count
    if num_parents > 0
      relative_parent = collection.parents.first
      html << '<h1 class="pt-title pt-compound-title">'
      html <<   '<small>'
      html <<     link_to(relative_parent.title, relative_parent)
      html <<   '</small>'
      html <<   '<br>'
      html <<   '&nbsp;&nbsp;&#8627; '
      html <<   collection.title
      html << '</h1>'
    else
      html << '<h1 class="pt-title">'
      html <<   collection.title
      html << '</h1>'
    end
    raw(html.string)
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