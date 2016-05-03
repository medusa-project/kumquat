module ItemsHelper

  DEFAULT_THUMBNAIL_SIZE = 256
  PAGE_TITLE_LENGTH = 35

  ##
  # @param bs [Bytestream]
  # @return [String]
  #
  def bytestream_exif_metadata_as_table(bs)
    data = bytestream_metadata_for(bs)
    html = ''
    if data[:exif].any?
      html += '<table class="table table-condensed pt-metadata">'
      data[:exif].each do |key, value|
        html += "<tr><td>#{raw(key)}</td><td>#{raw(value)}</td></tr>"
      end
      html += '</table>'
    end
    raw(html)
  end

  ##
  # @param bs [Bytestream]
  # @return [String]
  #
  def bytestream_file_metadata_as_table(bs)
    data = bytestream_metadata_for(bs)
    html = ''
    if data[:file].any?
      html += '<table class="table table-condensed pt-metadata">'
      data[:file].each do |key, value|
        html += "<tr><td>#{raw(key)}</td><td>#{raw(value)}</td></tr>"
      end
      html += '</table>'
    end
    raw(html)
  end

  ##
  # @param bs [Bytestream]
  # @return [String]
  #
  def bytestream_iptc_metadata_as_table(bs)
    data = bytestream_metadata_for(bs)
    html = ''
    if data[:iptc]
      html += "#{data[:iptc]}"
    end
    raw(html)
  end

  ##
  # @param bs [Bytestream]
  # @return [String]
  #
  def bytestream_xmp_metadata_as_table(bs)
    data = bytestream_metadata_for(bs)
    html = ''
    if data[:xmp]
      html += "<pre>#{h(data[:xmp])}</pre>"
    end
    raw(html)
  end

  ##
  # @param items [Relation]
  # @param options [Hash] Options hash
  # @option options [Boolean] :show_collection_facet
  # @option options [MetadataProfile] :metadata_profile
  #
  def facets_as_panels(items, options = {})
    return nil unless items.facet_fields # nothing to do

    def get_panel(title, terms, for_collections = false)
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

        if for_collections
          collection = Collection.find_by_repository_id(term.name)
          term_label = collection.title if collection
        else
          term_label = truncate(term.label, length: 80)
        end
        term_label = truncate(term_label, length: 80)

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

    # get the list of facets to display from the appropriate metadata profile
    collection_element = ElementDef.new(name: 'collection', facetable: true)
    profile_facetable_elements = [collection_element] +
        options[:metadata_profile].element_defs.where(facetable: true).
            order(:index)

    html = ''
    profile_facetable_elements.each do |element|
      result_facet = items.facet_fields.
          select{ |f| f.field == element.solr_facet_field }.first
      next unless result_facet and
          result_facet.terms.select{ |t| t.count > 0 }.any?
      is_collection_facet =
          (result_facet.field == Item::SolrFields::COLLECTION + Element.solr_facet_suffix)
      if is_collection_facet
        if !options[:show_collection_facet]
          next
        else
          html += get_panel('Collection', result_facet.terms, true)
        end
      else
        html += get_panel(element.label, result_facet.terms, false)
      end
    end
    raw(html)
  end

  ##
  # @param files [Relation<Item>]
  #
  def files_as_list(files)
    return nil unless files.any?
    html = '<ol>'
    files.each do |child|
      link_target = item_path(child)
      html += '<li>'
      html += '<div>'
      html += link_to(link_target) do
        raw('<div class="pt-thumbnail">' +
                thumbnail_tag(child, DEFAULT_THUMBNAIL_SIZE) + '</div>')
      end
      html += link_to(truncate(child.title, length: PAGE_TITLE_LENGTH),
                      link_target, class: 'pt-title')
      html += '</div></li>'
    end
    html += '</ol>'
    raw(html)
  end

  def files_panel(item)
    files = item.files
    html = ''
    if files.any?
      html += "<div class=\"panel panel-default\">
        <div class=\"panel-heading\">
          <h2 class=\"panel-title\">Files (#{files.count})</h2>
        </div>
        <div class=\"panel-body pt-pages\">
          #{files_as_list(files)}
        </div>
      </div>"
    end
    raw(html)
  end

  ##
  # @param item [Item]
  # @param options [Hash]
  # @option options [Integer] :size Thumbnail size
  # @return [String]
  #
  def front_matter_item_panel(item, options)
    unless options[:size]
      options[:size] = DEFAULT_THUMBNAIL_SIZE
    end
    html = ''
    if item.front_matter_item
      html += "<div class=\"panel panel-default pt-front-matter-item\">
          <div class=\"panel-heading\">
            <h2 class=\"panel-title\">Front Matter</h2>
          </div>
          <div class=\"panel-body\">"
      html += link_to(item.front_matter_item) do
        thumbnail_tag(item.front_matter_item, options[:size])
      end
      html += '</div>
              </div>'
    end
    raw(html)
  end

  ##
  # @param bs [Bytestream]
  # @return [String, nil] Base IIIF URL or nil if the bytestream is not an
  #                       image
  #
  def iiif_bytestream_url(bs)
    if bs and (bs.is_image? or bs.is_pdf?)
      id = bs.repository_relative_pathname.reverse.chomp('/').reverse
      return PearTree::Application.peartree_config[:iiif_url] + '/' +
          CGI.escape(id)
    end
    nil
  end

  ##
  # @param item [Item]
  # @return [String, nil] IIIF info.json URL or nil if the item is not an image
  #
  def iiif_item_info_url(item)
    url = iiif_item_url(item)
    url ? "#{url}/info.json" : nil
  end

  ##
  # @param item [Item]
  # @return [String, nil] Base IIIF URL or nil if the item is not an image
  #
  def iiif_item_url(item)
    url = nil
    bs = item.access_master_bytestream
    if !bs or (!bs.is_image? and !bs.is_pdf?)
      bs = item.preservation_master_bytestream
      if !bs or (!bs.is_image? and bs.is_pdf?)
        bs = nil
      end
    end
    if bs
      url = iiif_bytestream_url(bs)
    end
    url
  end

  ##
  # @param item [Item]
  # @param options [Hash]
  # @option options [Integer] :size Thumbnail size
  # @return [String]
  #
  def index_item_panel(item, options)
    unless options[:size]
      options[:size] = DEFAULT_THUMBNAIL_SIZE
    end
    html = ''
    if item.index_item
      html += "<div class=\"panel panel-default pt-index-item\">
          <div class=\"panel-heading\">
            <h2 class=\"panel-title\">Index</h2>
          </div>
          <div class=\"panel-body\">"
      html += link_to(item.index_item) do
        thumbnail_tag(item.index_item, options[:size])
      end
      html += '</div>
              </div>'
    end
    raw(html)
  end

  ##
  # @param item [Item]
  # @return [Boolean]
  #
  def is_favorite?(item)
    cookies[:favorites] and cookies[:favorites].
        split(FavoritesController::COOKIE_DELIMITER).
        select{ |f| f == item.repository_id }.any?
  end

  ##
  # @param item [Item]
  # @return [String] HTML string
  #
  def item_page_title(item)
    html = ''
    if item.parent or item.items.any?
      relative_parent = item.parent ? item.parent : item
      relative_child = item.parent ? item : relative_parent
      html += '<h1 class="pt-compound-title">'
      if item.parent
        html += "<small>#{link_to relative_parent.title, relative_parent}</small>"
        html += "<br>&nbsp;&nbsp;&#8627; "
      end
      html += "#{icon_for(relative_child)} #{relative_child.title}</h1>"
    else
      html += "<h1>#{icon_for(item)} #{item.title}"
      if item.subtitle
        html += "<br><small>#{item.subtitle}</small>"
      end
      html += '</h1>'
    end
    raw(html)
  end

  ##
  # @param items [Relation<Item>]
  # @param start [integer]
  # @param options [Hash] with available keys:
  # :link_to_admin (boolean), :show_remove_from_favorites_buttons (boolean),
  # :show_add_to_favorites_buttons (boolean),
  # :show_collections (boolean), :show_description (boolean),
  # :thumbnail_size (integer)
  #
  def items_as_list(items, start, options = {})
    options[:show_description] = true unless
        options.keys.include?(:show_description)

    html = "<ol start=\"#{start + 1}\">"
    items.each do |item|
      next unless item # item may be nil in testing
      link_target = options[:link_to_admin] ?
          admin_item_path(item) : polymorphic_path(item)
      html += '<li>'\
        '<div>'
      html += link_to(link_target, class: 'pt-thumbnail-link') do
        raw('<div class="pt-thumbnail">' +
          thumbnail_tag(item.effective_representative_item,
                        options[:thumbnail_size] ? options[:thumbnail_size] : 256) +
        '</div>')
      end
      html += '<span class="pt-title">'
      html += link_to(item.title, link_target)

      # info line
      info_parts = []
      info_parts << "#{icon_for(item)}#{type_of(item)}"

      num_pages = item.pages.count
      if num_pages > 0
        info_parts << "#{num_pages} pages"
      else
        num_files = item.files.count
        if num_files > 0
          info_parts << "#{num_files} files"
        else
          num_children = item.items.count
          if num_children > 0
            info_parts << "#{num_children} sub-items"
          end
        end
      end

      date = item.date
      if date
        info_parts << date.year
      end

      if options[:show_collections]
        info_parts << link_to(item.collection.title,
                              collection_path(item.collection))
      end

      html += "<br><span class=\"pt-info-line\">#{info_parts.join(' | ')}</span>"

      # remove-from-favorites button
      if options[:show_remove_from_favorites_buttons]
        html += ' <button class="btn btn-xs btn-danger ' +
            'pt-remove-from-favorites" data-item-id="' + item.repository_id + '">'
        html += '<i class="fa fa-heart"></i> Remove'
        html += '</button>'
      end
      # add-to-favorites button
      if options[:show_add_to_favorites_buttons]
        html += ' <button class="btn btn-default btn-xs ' +
            'pt-add-to-favorites" data-item-id="' + item.repository_id + '">'
        html += '<i class="fa fa-heart-o"></i>'
        html += '</button>'
      end

      html += '</span>'
      if options[:show_description]
        html += '<br>'
        html += '<span class="pt-description">'
        html += truncate(item.description.to_s, length: 400)
        html += '</span>'
      end
      html += '</div>'
      html += '</li>'
    end
    html += '</ol>'
    raw(html)
  end

  ##
  # @param item [Item]
  # @param options [Hash]
  # @option options [Integer] :size Thumbnail size
  # @return [String]
  #
  def key_item_panel(item, options)
    unless options[:size]
      options[:size] = DEFAULT_THUMBNAIL_SIZE
    end
    html = ''
    if item.key_item
      html += "<div class=\"panel panel-default pt-key-item\">
          <div class=\"panel-heading\">
            <h2 class=\"panel-title\">Key</h2>
          </div>
          <div class=\"panel-body\">"
      html += link_to(item.key_item) do
        thumbnail_tag(item.key_item, options[:size])
      end
      html += '</div>
              </div>'
    end
    raw(html)
  end

  ##
  # @param item [Item]
  # @return [String]
  # @see `tech_metadata_as_list`
  #
  def metadata_as_list(item)
    html = '<dl class="pt-metadata">'
    # iterate through the index-ordered elements in the collection's metadata
    # profile in order to display the entity's elements in the correct order
    item.collection.effective_metadata_profile.element_defs.each do |e_def|
      elements = item.elements.
          select{ |e| e.name == e_def.name and e.value.present? }
      next if elements.empty?
      html += "<dt>#{e_def.label}</dt>"
      html += '<dd>'
      if elements.length == 1
        html += elements.first.formatted_value
      else
        html += '<ul>'
        elements.each do |element|
          html += "<li>#{element.formatted_value}</li>"
        end
        html += '</ul>'
      end
      html += '</dd>'
    end
    html += '</dl>'
    raw(html)
  end

  ##
  # @param item [Item]
  # @return [String]
  # @see `tech_metadata_as_table`
  #
  def metadata_as_table(item)
    html = '<table class="table table-condensed pt-metadata">'

    # iterate through the index-ordered elements in the collection's metadata
    # profile in order to display the entity's elements in the correct order
    item.collection.effective_metadata_profile.element_defs.each do |e_def|
      elements = item.elements.
          select{ |e| e.name == e_def.name and e.value.present? }
      next if elements.empty?
      html += '<tr>'
      html += "<td>#{e_def.label}</td>"
      html += '<td>'
      if elements.length == 1
        html += elements.first.formatted_value
      else
        html += '<ul>'
        elements.each do |element|
          html += "<li>#{element.formatted_value}</li>"
        end
        html += '</ul>'
      end
      html += '</td>'
      html += '</tr>'
    end
    html += '</table>'
    raw(html)
  end

  ##
  # @return [Relation]
  #
  def more_like_this
    Relation.new(self).more_like_this
  end

  ##
  # @param search_term [String]
  # @param suggestions [Array<String>]
  # @return [String] HTML string
  #
  def no_results_help(search_term, suggestions)
    html = ''
    if search_term.present?
      html += "<p class=\"alert alert-warning\">Sorry, we couldn't find "\
      "anything matching &quot;#{h(search_term)}&quot;.</p>"
      if suggestions.any?
        html += "<p>Did you mean:</p><ul>"
        suggestions.each do |suggestion|
          html += "<li>#{link_to(suggestion, { q: suggestion })}?</li>"
        end
        html += '</ul>'
      end
    else
      html += '<p>No items.</p>'
    end
    raw(html)
  end

  ##
  # @return [Integer]
  #
  def num_favorites
    cookies[:favorites] ?
        cookies[:favorites].split(FavoritesController::COOKIE_DELIMITER).length : 0
  end

  def page_select_menu(item)
    pages = item.parent ? item.parent.pages : item.pages
    pages = pages

    html = '<select class="form-control input-sm pt-page-select">'
    pages.each_with_index do |page, index|
      selected = (page.repository_id == item.repository_id) ? 'selected' : ''
      html += "<option value=\"#{item_path(page)}\" #{selected}>
        #{page.title} (#{index + 1} of #{pages.count})
        </option>"
    end
    html += '</select>'
    raw(html)
  end

  ##
  # @param item [Item]
  # @param options [Hash] with available keys: `:link_to_admin` [Boolean]
  #
  def pages_as_list(item, options = {})
    items = item.parent ? item.parent.pages : item.pages
    items = items.limit(999)
    return nil unless items.any?
    html = '<ol>'
    items.each do |child|
      link_target = options[:link_to_admin] ?
          admin_item_path(child) : item_path(child)
      html += '<li>'
      if item.repository_id == child.repository_id
        html += '<div class="pt-current">'
        html += raw('<div class="pt-thumbnail">' +
                        thumbnail_tag(child, 256) +
                        '</div>')
        html += '<span class=\"pt-title\">' +
            truncate(child.title, length: PAGE_TITLE_LENGTH) + '</span>'
      else
        html += '<div>'
        html += link_to(link_target) do
          raw('<div class="pt-thumbnail">' +
                  thumbnail_tag(child, DEFAULT_THUMBNAIL_SIZE) + '</div>')
        end
        html += link_to(truncate(child.title, length: PAGE_TITLE_LENGTH),
                        link_target, class: 'pt-title')
      end
      html += '</div></li>'
    end
    html += '</ol>'
    raw(html)
  end

  def pages_panel(pages, selected_page)
    html = ''
    if pages.any?
      html += "<div class=\"panel panel-default\">
        <div class=\"panel-heading\">
          <h2 class=\"panel-title\">Pages (#{pages.count})</h2>
        </div>
        <div class=\"panel-body pt-pages\">
          #{pages_as_list(selected_page)}
        </div>
      </div>"
    end
    raw(html)
  end

  ##
  # @param items [Relation]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate(items, per_page, current_page, max_links = 9)
    return '' unless items.total_length > per_page
    num_pages = (items.total_length / per_page.to_f).ceil
    first_page = [1, current_page - (max_links / 2.0).floor].max
    last_page = [first_page + max_links - 1, num_pages].min
    first_page = last_page - max_links + 1 if
        last_page - first_page < max_links and num_pages > max_links
    prev_page = [1, current_page - 1].max
    next_page = [last_page, current_page + 1].min
    prev_start = (prev_page - 1) * per_page
    next_start = (next_page - 1) * per_page
    last_start = (num_pages - 1) * per_page

    first_link = link_to(params.except(:start), 'aria-label' => 'First') do
      raw('<span aria-hidden="true">First</span>')
    end
    prev_link = link_to(params.merge(start: prev_start), 'aria-label' => 'Previous') do
      raw('<span aria-hidden="true">&laquo;</span>')
    end
    next_link = link_to(params.merge(start: next_start), 'aria-label' => 'Next') do
      raw('<span aria-hidden="true">&raquo;</span>')
    end
    last_link = link_to(params.merge(start: last_start), 'aria-label' => 'Last') do
      raw('<span aria-hidden="true">Last</span>')
    end

    # http://getbootstrap.com/components/#pagination
    html = '<nav>' +
      '<ul class="pagination">' +
        "<li #{current_page == first_page ? 'class="disabled"' : ''}>#{first_link}</li>" +
        "<li #{current_page == prev_page ? 'class="disabled"' : ''}>#{prev_link}</li>"
    (first_page..last_page).each do |page|
      start = (page - 1) * per_page
      page_link = link_to((start == 0) ? params.except(:start) : params.merge(start: start)) do
        raw("#{page} #{(page == current_page) ?
                '<span class="sr-only">(current)</span>' : ''}")
      end
      html += "<li class=\"#{page == current_page ? 'active' : ''}\">" +
            page_link + '</li>'
    end
    html += "<li #{current_page == next_page ? 'class="disabled"' : ''}>#{next_link}</li>" +
        "<li #{current_page == last_page ? 'class="disabled"' : ''}>#{last_link}</li>"
      '</ul>' +
    '</nav>'
    raw(html)
  end

  ##
  # Returns the status of a search or browse action, e.g. "Showing n of n
  # items".
  #
  # @param items [Relation]
  # @param start [Integer]
  # @param num_results_shown [Integer]
  # @return [String]
  #
  def search_status(items, start, num_results_shown)
    total = items.total_length
    last = [total, start + num_results_shown].min
    raw("Showing #{start + 1}&ndash;#{last} of #{total} items")
  end

  ##
  # @param item [Item]
  # @return [String] HTML string
  #
  def share_button(item)
    html = '<div class="btn-group">
      <button type="button" class="btn btn-default dropdown-toggle"
            data-toggle="dropdown" aria-expanded="false">
        <i class="fa fa-share-alt"></i> Share <span class="caret"></span>
      </button>'
    html += '<ul class="dropdown-menu" role="menu">'
    description = item.description ? CGI::escape(item.description) : nil
    # email
    html += '<li>'
    html += link_to("mailto:?subject=#{item.title}&body=#{item_url(item)}") do
      raw('<i class="fa fa-envelope"></i> Email')
    end
    html += '</li>'
    html += '<li class="divider"></li>'
    # facebook
    html += '<li>'
    html += link_to("https://www.facebook.com/sharer/sharer.php?u=#{CGI::escape(item_url(item))}") do
      raw('<i class="fa fa-facebook-square"></i> Facebook')
    end
    html += '</li>'
    # linkedin
    html += '<li>'
    html += link_to("http://www.linkedin.com/shareArticle?mini=true&url=#{CGI::escape(item_url(item))}&title=#{CGI::escape(item.title)}&summary=#{description}") do
      raw('<i class="fa fa-linkedin-square"></i> LinkedIn')
    end
    html += '</li>'
    # twitter
    html += '<li>'
    html += link_to("http://twitter.com/home?status=#{CGI::escape(item.title)}%20#{CGI::escape(item_url(item))}") do
      raw('<i class="fa fa-twitter-square"></i> Twitter')
    end
    html += '</li>'
    # google+
    html += '<li>'
    html += link_to("https://plus.google.com/share?url=#{CGI::escape(item.title)}%20#{CGI::escape(item_url(item))}") do
      raw('<i class="fa fa-google-plus-square"></i> Google+')
    end
    html += '</li>'
    # pinterest
    url = "http://pinterest.com/pin/create/button/?url=#{CGI::escape(item_url(item))}&description=#{CGI::escape(item.title)}"
    iiif_url = item_image_url(item, 512)
    url += "&media=#{CGI::escape(iiif_url)}" if iiif_url
    html += '<li>'
    html += link_to(url) do
      raw('<i class="fa fa-pinterest-square"></i> Pinterest')
    end
    html += '</li>'

    html += '</ul>'
    html += '</div>'
    raw(html)
  end

  ##
  # @param item [Item]
  # @param limit [Integer]
  # @return [String] HTML unordered list
  #
  def similar_items_as_list(item, limit = 5)
    html = ''
    items = item.more_like_this.limit(limit)
    if items.any?
      html += '<ul>'
      items.each do |item|
        html += '<li>'
        html += '<div class="pt-thumbnail">'
        html += link_to(item_path(item)) do
          thumbnail_tag(item, 256)
        end
        html += '</div>'
        html += link_to(truncate(item.title, length: 40),
                        item_path(item), class: 'pt-title')
        html += '</li>'
      end
      html += '</ul>'
    end
    raw(html)
  end

  ##
  # Returns a sort pulldown menu for the given metadata profile. If there are
  # no sortable elements in the profile, returns a zero-length string.
  #
  # @param metadata_profile [MetadataProfile]
  # @return [String] HTML form element
  #
  def sort_menu(metadata_profile)
    sortable_elements = metadata_profile.element_defs.where(sortable: true)
    default_sortable_element = metadata_profile.default_sortable_element_def
    html = ''
    if sortable_elements.any?
      html += '<form class="form-inline" method="GET">
        <div class="form-group">
          <select name="sort" class="form-control input-sm">'

      unless default_sortable_element
        html += '<option value="">Sort by Relevance</option>'
      end

      # If there is an element in the ?sort= query, select that. Otherwise,
      # select the metadata profile's default sort element.
      selected_element = sortable_elements.
          select{ |e| e.solr_single_valued_field == params[:sort] }.first
      if !selected_element and default_sortable_element
        selected_element =
            sortable_elements.find_by_name(default_sortable_element.name)
      end
      sortable_elements.each do |e|
        selected = (e == selected_element) ? 'selected' : ''
        html += "<option value=\"#{e.solr_single_valued_field}\" #{selected}>"\
          "Sort by #{e.label}</option>"
      end
      html += '</select>
        </div>
      </form>'
    end
    raw(html)
  end

  ##
  # @param item [Item]
  # @return [String]
  # @see `metadata_as_list`
  #
  def tech_metadata_as_list(item)
    data = tech_metadata_for(item)
    html = '<dl class="pt-metadata">'
    data.each do |key, value|
      html += "<dt>#{raw(key)}</dt><dd>#{raw(value)}</dd>"
    end
    html += '</dl>'
    raw(html)
  end

  ##
  # @param item [Item]
  # @return [String]
  # @see `metadata_as_table`
  #
  def tech_metadata_as_table(item)
    data = tech_metadata_for(item)
    html = '<table class="table table-condensed pt-metadata">'
    data.each do |key, value|
      html += "<tr><td>#{raw(key)}</td><td>#{raw(value)}</td></tr>"
    end
    html += '</table>'
    raw(html)
  end

  ##
  # @param entity [Item, Bytestream] or some other object suitable for passing
  #                                  to `icon_for`
  # @param size [Integer]
  # @return [String]
  #
  def thumbnail_tag(entity, size)
    html = ''
    if entity.kind_of?(Bytestream)
      url = bytestream_image_url(entity, size)
      if url
        # no alt because it may appear in a huge font size if the image is 404
        html += image_tag(url, alt: '')
      else
        html += icon_for(entity) # ApplicationHelper
      end
    elsif entity.kind_of?(Item)
      url = item_image_url(entity, size)
      if url
        # no alt because it may appear in a huge font size if the image is 404
        html += image_tag(url, alt: '')
      else
        html += icon_for(entity) # ApplicationHelper
      end
    else
      html += icon_for(entity) # ApplicationHelper
    end
    raw(html)
  end

  ##
  # @param item [Item]
  # @param options [Hash]
  # @option options [Integer] :size Thumbnail size
  # @return [String]
  #
  def title_item_panel(item, options)
    unless options[:size]
      options[:size] = DEFAULT_THUMBNAIL_SIZE
    end
    html = ''
    if item.title_item
      html += "<div class=\"panel panel-default pt-title-item\">
          <div class=\"panel-heading\">
            <h2 class=\"panel-title\">Title</h2>
          </div>
          <div class=\"panel-body\">"
      html += link_to(item.title_item) do
        thumbnail_tag(item.title_item, options[:size])
      end
      html += '</div>
              </div>'
    end
    raw(html)
  end

  ##
  # @param item [Item]
  #
  def viewer_for(item)
    if item.is_pdf?
      return pdf_viewer_for(item)
    elsif item.is_image?
      return image_viewer_for(item)
    elsif item.is_audio?
      return audio_player_for(item)
    elsif item.is_text?
      bs = item.access_master_bytestream || item.preservation_master_bytestream
      pathname = bs.absolute_local_pathname
      return raw("<pre>#{File.read(pathname)}</pre>")
    elsif item.is_video?
      return video_player_for(item)
    end
    nil
  end

  private

  def audio_player_for(item)
    bs = item.bytestreams.
        where(bytestream_type: Bytestream::Type::ACCESS_MASTER).first
    tag = "<audio controls>
      <source src=\"#{item_access_master_bytestream_url(item)}\"
              type=\"#{bs.media_type}\">
        Your browser does not support the audio tag.
    </audio>"
    raw(tag)
  end

  ##
  # @param bs [Bytestream]
  # @param size [Integer]
  # @param shape [Symbol] :default or :square
  # @return [String, nil] Image URL or nil if the item is not an image
  #
  def bytestream_image_url(bs, size, shape = :default)
    url = nil
    if (bs.is_image? or bs.is_pdf?) and bs.file_group_relative_pathname
      shape = (shape == :default) ? 'full' : 'square'
      url = sprintf('%s/%s/!%d,%d/0/default.jpg',
                     iiif_bytestream_url(bs), shape, size, size)
    end
    url
  end

  ##
  # @return [Hash] Hash with `:file`, `:exif`, `:iptc`, and `:xmp` keys
  #
  def bytestream_metadata_for(bytestream)
    data = { file: {}, exif: {}, iptc: nil, xmp: nil }
    if bytestream
      # development-only info
      if Rails.env.development?
        data[:file]['Pathname (DEVELOPMENT)'] =
            bytestream.absolute_local_pathname || bytestream.url
      end
      # filename
      if bytestream.file_group_relative_pathname or bytestream.url
        data[:file]['Filename'] =
            File.basename(bytestream.file_group_relative_pathname || bytestream.url)
      end
      # status
      data[:file]['Status'] = bytestream.exists? ?
          '<span class="label label-success">OK</span>' :
          '<span class="label label-danger">MISSING</span>'
      # media type
      data[:file]['Media Type'] = bytestream.media_type
      # size
      size = bytestream.byte_size
      if size
        data[:file]['Size'] = number_to_human_size(size)
      end
      if bytestream.is_image?
        # EXIF
        bytestream.exif.each do |k, v|
          key_name = k.to_s.gsub('_', ' ').titleize
          if k.to_s == 'orientation'
            data[:exif][key_name] = v.to_i.to_s
          else
            data[:exif][key_name] = truncate(v.to_s, length: 400)
          end
        end
        # IPTC
        data[:iptc] = bytestream.iptc
        # XMP
        data[:xmp] = bytestream.xmp
      end
      if bytestream.is_image? or bytestream.is_video?
        if bytestream.width and bytestream.height
          data[:file]['Dimensions'] =
              "#{bytestream.width}&times;#{bytestream.height} pixels"
        end
      end
    end
    data
  end

  def image_viewer_for(item)
    html = "<div id=\"pt-image-viewer\"></div>
    #{javascript_include_tag('/openseadragon/openseadragon.min.js')}
    <script type=\"text/javascript\">
    var viewer = OpenSeadragon({
        id: \"pt-image-viewer\",
        showNavigator: true,
        navigatorPosition: \"ABSOLUTE\",
        navigatorTop: \"40px\",
        navigatorLeft: \"4px\",
        navigatorHeight: \"120px\",
        navigatorWidth: \"145px\",
        preserveViewport: true,
        prefixUrl: \"/openseadragon/images/\",
        tileSources: \"#{j(iiif_item_url(item))}\"
    });
    </script>"
    raw(html)
  end

  ##
  # @param [Item] item
  # @param [Integer] size
  # @return [String, nil] Image URL or nil if the item is not an image
  #
  def item_image_url(item, size)
    if item.is_image? or item.is_pdf?
      bs = item.access_master_bytestream || item.preservation_master_bytestream
      if bs.file_group_relative_pathname
        return sprintf('%s/full/!%d,%d/0/default.jpg',
                       iiif_item_url(item), size, size)
      end
    end
    nil
  end

  def pdf_viewer_for(item)
    link_to(item_access_master_bytestream_url(item)) do
      thumbnail_tag(item, 256)
    end
  end

  def video_player_for(item)
    bs = item.access_master_bytestream
    tag = "<video controls id=\"pt-video-player\">
      <source src=\"#{item_access_master_bytestream_url(item)}\"
              type=\"#{bs.media_type}\">
        Your browser does not support the video tag.
    </video>"
    raw(tag)
  end

  ##
  # @param [Bytestream] bytestream
  #
  def download_label_for_bytestream(bytestream)
    format = bytestream.url ? 'External Resource' : bytestream.human_readable_name

    dimensions = nil
    if bytestream.width and bytestream.width > 0 and bytestream.height and
        bytestream.height > 0
      dimensions = "#{bytestream.width}&times;#{bytestream.height}"
    end

    size = bytestream.byte_size
    size = "(#{number_to_human_size(size)})" if size

    raw("#{format} #{dimensions} #{size}")
  end

  def tech_metadata_for(item)
    data = {}
    data['Created'] = local_time_ago(item.created_at)
    data['Last Modified'] = local_time_ago(item.updated_at)
    data['Last Indexed'] = local_time_ago(item.last_indexed)
    url = iiif_item_url(item)
    data[link_to('IIIF Image URL', 'http://iiif.io/')] = link_to(url, url) if url
    data
  end

end
