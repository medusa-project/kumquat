module CollectionsHelper

  ##
  # @param collections [Relation]
  #
  def collection_facets_as_panels(collections)
    return nil unless collections.facet_fields # nothing to do

    html = ''
    Collection::solr_facet_fields.each do |field|
      result_facet = collections.facet_fields.
          select{ |f| f.field == field[:name] }.first
      next unless result_facet and
          result_facet.terms.select{ |t| t.count > 0 }.any?

      html += collection_facet_panel(field[:label], field[:id],
                                     result_facet.terms)
    end
    raw(html)
  end

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
      begin
        # If the reference to the bytestream is invalid (for example, an
        # invalid UUID has been entered), this will raise an error.
        bs = col.representative_image_bytestream
      rescue => e
        Rails.logger.warn("collections_as_cards(): #{e} (#{col})")
      end
      if bs
        img_url = bytestream_image_url(bs, thumb_size, :square)
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
    elsif collection.published and collection.access_url and
        collection.access_url.length > 0
      return collection.access_url
    end
    nil
  end

  private

  def collection_facet_panel(title, id, terms)
    panel = "<div class=\"panel panel-default\" id=\"#{id}\">
      <div class=\"panel-heading\">
        <h3 class=\"panel-title\">#{title}</h3>
      </div>
      <div class=\"panel-body\">
        <ul>"
    terms.each_with_index do |term, i|
      break if i >= Option::integer(Option::Key::FACET_TERM_LIMIT)
      next if term.count < 1
      checked = (params[:fq] and params[:fq].include?(term.facet_query)) ?
          'checked' : nil
      checked_params = term.removed_from_params(params.deep_dup)
      unchecked_params = term.added_to_params(params.deep_dup)
      checked_params.delete(:start)
      unchecked_params.delete(:start)
      term_label = truncate(term.label, length: 80)

      panel += "<li class=\"pt-term\">"
      panel += "  <div class=\"checkbox\">"
      panel += "    <label>"
      panel += "      <input type=\"checkbox\" name=\"pt-facet-term\" #{checked} "\
               "          data-query=\"#{term.facet_query.gsub('"', '&quot;')}\" "\
               "          data-checked-href=\"#{url_for(unchecked_params)}\" "\
               "          data-unchecked-href=\"#{url_for(checked_params)}\">"
      panel += "      <span class=\"pt-term-name\">#{term_label}</span> "
      panel += "      <span class=\"pt-count badge\">#{term.count}</span>"
      panel += "    </label>"
      panel += "  </div>"
      panel += "</li>"
    end
    raw(panel + '</ul></div></div>')
  end

end