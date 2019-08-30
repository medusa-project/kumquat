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
      html << '<h1 class="dl-title dl-compound-title">'
      html <<   '<small>'
      html <<     link_to(relative_parent.title, relative_parent)
      html <<   '</small>'
      html <<   '<br>'
      html <<   '&nbsp;&nbsp;&#8627; '
      html <<   collection.title
      html << '</h1>'
    else
      html << '<h1 class="dl-title">'
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

  def repository_link(collection)
    url = Configuration.instance.metadata_gateway_url +
        "/collections?fq%5B%5D=local_facet_repository%3A" +
        collection.medusa_repository.title
    link_to collection.medusa_repository.title, url
  end

end