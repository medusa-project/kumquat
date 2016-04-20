module CollectionsHelper

  ##
  # @param collections [Relation]
  #
  def collection_facets_as_panels(collections)
    return nil unless collections.facet_fields # nothing to do

    def get_panel(title, terms)
      panel = "<div class=\"panel panel-default\">
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
        term_label = truncate(term.label&.titleize, length: 80)

        panel += "<li class=\"pt-term\">"
        panel += "<div class=\"checkbox\">"
        panel += "<label>"
        panel += "<input type=\"checkbox\" name=\"pt-facet-term\" #{checked} "\
        "data-checked-href=\"#{url_for(unchecked_params)}\" "\
        "data-unchecked-href=\"#{url_for(checked_params)}\">"
        panel += "<span class=\"pt-term-name\">#{term_label}</span> "
        panel += "<span class=\"pt-count badge\">#{term.count}</span>"
        panel += "</label>"
        panel += "</div>"
        panel += "</li>"
      end
      raw(panel + '</ul></div></div>')
    end

    html = ''
    Collection::solr_facet_fields.each do |field|
      result_facet = collections.facet_fields.
          select{ |f| f.field == field[:name] }.first
      next unless result_facet and
          result_facet.terms.select{ |t| t.count > 0 }.any?

      html += get_panel(field[:label], result_facet.terms)
    end
    raw(html)
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