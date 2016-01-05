module ItemsHelper

  ##
  # @param item [Item]
  # @param options [Hash] with available keys: `:for_admin` (boolean)
  #
  def download_button(item, options = {})
    html = ''
    bytestreams = item.bytestreams.select{ |bs| bs.exists? }
    if bytestreams.any?
      html = '<div class="btn-group">
        <button type="button" class="btn btn-default dropdown-toggle"
             data-toggle="dropdown" aria-expanded="false">
          <i class="fa fa-download"></i> Download <span class="caret"></span>
        </button>'
      html += '<ul class="dropdown-menu pull-right" role="menu">'

      bytestreams.each do |bs|
        html += '<li>'
        if bs.url
          url = bs.url
        elsif bs.type == Bytestream::Type::ACCESS_MASTER
          url = item_access_master_bytestream_url(item)
        elsif bs.type == Bytestream::Type::PRESERVATION_MASTER
          url = item_preservation_master_bytestream_url(item)
        else
          url = '#'
        end
        html += link_to(url) do
          download_label_for_bytestream(bs)
        end
        html += '</li>'
      end

      if options[:for_admin]
        #json_ld_url = admin_item_url(item, format: :jsonld)
        #rdf_xml_url = admin_item_url(item, format: :rdfxml)
        #ttl_url = admin_item_url(item, format: :ttl)
      else
        #json_ld_url = item_url(item, format: :jsonld)
        #rdf_xml_url = item_url(item, format: :rdfxml)
        #ttl_url = item_url(item, format: :ttl)
      end

      html += '</ul>'
      html += '</div>'
    end
    raw(html)
  end

  ##
  # @param items [Relation]
  # @param options [Hash] Options hash.
  # @option options [Boolean] :show_collection_facet
  # @option options [MetadataProfile] :metadata_profile
  #
  def facets_as_panels(items, options = {})
    return nil unless items.facet_fields # nothing to do

    # get the list of facets to display from the appropriate metadata profile
    profile = options[:metadata_profile] ||
        MetadataProfile.where(default: true).limit(1).first
    collection_element = ElementDef.new(
        facet_def: FacetDef.find_by_name('Collection'),
        facet_def_label: 'Collection')
    profile_facetable_elements = [collection_element] +
        profile.element_defs.where('facet_def_id IS NOT NULL').order(:index)

    term_limit = Option::integer(Option::Key::FACET_TERM_LIMIT)

    html = ''
    profile_facetable_elements.each do |element|
      result_facet = items.facet_fields.
          select{ |f| f.field == element.facet_def.solr_field }.first
      next unless result_facet and
          result_facet.terms.select{ |t| t.count > 0 }.any?
      next if result_facet.field == 'pt_collection_facet' and
          !options[:show_collection_facet]
      panel = "<div class=\"panel panel-default\">
      <div class=\"panel-heading\">
        <h3 class=\"panel-title\">#{element.facet_def_label}</h3>
      </div>
      <div class=\"panel-body\">
        <ul>"
      result_facet.terms.each_with_index do |term, i|
        break if i >= term_limit
        next if term.count < 1
        checked = (params[:fq] and params[:fq].include?(term.facet_query)) ?
            'checked' : nil
        checked_params = term.removed_from_params(params.deep_dup)
        unchecked_params = term.added_to_params(params.deep_dup)
        checked_params.delete(:start)
        unchecked_params.delete(:start)

        if result_facet.field == 'collection_facet'
          collection = Collection.find_by_id(term.name)
          term_label = collection.title if collection
        else
          term_label = truncate(term.label, length: 80)
        end

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
      html += panel + '</ul></div></div>'
    end
    raw(html)
  end

  ##
  # @param [Item] item
  # @return [String, nil] Base IIIF URL or nil if the item is not an image
  #
  def iiif_url(item)
    if item.is_image?
      return sprintf('%s/%s',
                     PearTree::Application.peartree_config[:iiif_url],
                     URI.escape(item.id))

    end
    nil
  end

  ##
  # @param item [Repository::Item]
  #
  def is_favorite?(item)
    cookies[:favorites] and cookies[:favorites].
        split(FavoritesController::COOKIE_DELIMITER).
        select{ |f| f == item.web_id }.any?
  end

  ##
  # @param items [ActiveMedusa::Relation]
  # @param start [integer]
  # @param options [Hash] with available keys:
  # :link_to_admin (boolean), :show_remove_from_favorites_buttons (boolean),
  # :show_add_to_favorites_buttons (boolean),
  # :show_collections (boolean), :show_description (boolean),
  # :thumbnail_size (integer),
  # :thumbnail_shape (Repository::Bytestream::Shape constant)
  #
  def items_as_list(items, start, options = {})
    options[:show_description] = true unless
        options.keys.include?(:show_description)
    options[:thumbnail_shape] = Bytestream::Shape::ORIGINAL unless
        options.keys.include?(:thumbnail_shape)

    html = "<ol start=\"#{start + 1}\">"
    items.each do |entity|
      link_target = polymorphic_path(entity)
      #link_target = options[:link_to_admin] ?
      #    admin_item_path(entity) : polymorphic_path(entity)
      html += '<li>'\
        '<div>'
      html += link_to(link_target, class: 'pt-thumbnail-link') do
        item = entity.representative_item
        raw('<div class="pt-thumbnail">' +
          thumbnail_tag(item,
                        options[:thumbnail_size] ? options[:thumbnail_size] : 256,
                        options[:thumbnail_shape]) +
        '</div>')
      end
      html += '<span class="pt-title">'
      html += icon_for(entity)
      html += link_to(entity.title, link_target)
      if entity.kind_of?(Item)
        # page count
        num_children = entity.children.total_length
        if num_children > 0
          html += " <span class=\"pt-count badge\">#{num_children} pages</span> "
        end
        # remove-from-favorites button
        if options[:show_remove_from_favorites_buttons]
          html += ' <button class="btn btn-xs btn-danger ' +
              'pt-remove-from-favorites" data-web-id="' + entity.id + '">'
          html += '<i class="fa fa-heart"></i> Remove'
          html += '</button>'
        end
        # add-to-favorites button
        if options[:show_add_to_favorites_buttons]
          html += ' <button class="btn btn-default btn-xs ' +
              'pt-add-to-favorites" data-web-id="' + entity.id + '">'
          html += '<i class="fa fa-heart-o"></i>'
          html += '</button>'
        end
        # collection
        if options[:show_collections]
          html += '<br>'
          html += link_to(entity.collection, class: 'pt-collection-title') do
            raw("#{self.icon_for(entity.collection)} #{entity.collection.title}")
          end
        end
      end
      html += '</span>'
      if options[:show_description]
        html += '<br>'
        html += '<span class="pt-description">'
        html += truncate(entity.description.to_s, length: 400)
        html += '</span>'
      end
      html += '</div>'
      html += '</li>'
    end
    html += '</ol>'
    raw(html)
  end

  ##
  # @param entity [Entity]
  # @return [String]
  # @see `tech_metadata_as_list`
  #
  def metadata_as_list(entity)
    html = '<dl class="pt-metadata">'
    # iterate through the index-ordered elements in the collection's metadata
    # profile in order to display the entity's elements in the correct order
    collection = entity.kind_of?(Collection) ? entity : entity.collection
    collection.collection_def.metadata_profile.element_defs.each do |e_def|
      elements = entity.metadata.select{ |e| e.name == e_def.name }
      next if elements.empty?
      html += "<dt>#{e_def.label}</dt>"
      html += '<dd>'
      if elements.length == 1
        html += elements.first.value
      else
        html += '<ul>'
        elements.each do |element|
          html += "<li>#{element.value}</li>"
        end
        html += '</ul>'
      end
      html += '</dd>'
    end
    html += '</dl>'
    raw(html)
  end

  ##
  # @param entity [Entity]
  # @return [String]
  # @see `tech_metadata_as_table`
  #
  def metadata_as_table(entity)
    html = '<table class="table table-condensed pt-metadata">'

    # iterate through the index-ordered elements in the collection's metadata
    # profile in order to display the entity's elements in the correct order
    collection = entity.kind_of?(Collection) ? entity : entity.collection
    collection.collection_def.metadata_profile.element_defs.each do |e_def|
      elements = entity.metadata.select{ |e| e.name == e_def.name }
      next if elements.empty?
      html += '<tr>'
      html += "<td>#{e_def.label}</td>"
      html += '<td>'
      if elements.length == 1
        html += elements.first.value
      else
        html += '<ul>'
        elements.each do |element|
          html += "<li>#{element.value}</li>"
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

  ##
  # @param item [Item]
  # @param options [Hash] with available keys: `:link_to_admin` [Boolean]
  #
  def pages_as_list(item, options = {})
    return nil unless item.children.any? or item.parent
    items = item.children.any? ? item.items : item.parent.children
    html = '<ol>'
    items.limit(999).each do |child|
      link_target = options[:link_to_admin] ?
          admin_item_path(child) : item_path(child)
      html += '<li><div>'
      if item == child
        html += raw('<div class="pt-thumbnail">' +
            thumbnail_tag(child, 256) +
            '</div>')
        html += "<strong class=\"pt-text pt-title\">#{truncate(child.title, length: 40)}</strong>"
      else
        html += link_to(link_target) do
          raw('<div class="pt-thumbnail">' + thumbnail_tag(child, 256) + '</div>')
        end
        html += link_to(truncate(child.title, length: 40), link_target,
                        class: 'pt-title')
      end
      html += '</div></li>'
    end
    html += '</ol>'
    raw(html)
  end

  ##
  # @param items [Array]
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
  # @param items [ActiveMedusa::Relation]
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
    html += '<ul class="dropdown-menu pull-right" role="menu">'
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
    iiif_url = image_url(item, 512)
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
          thumbnail_tag(item, 256, Bytestream::Shape::SQUARE)
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
  # @param item [Item]
  # @return [String]
  # @see `metadata_as_list`
  #
  def tech_metadata_as_list(item)
    data = tech_metadata_for(item)
    html = '<dl class="pt-metadata">'
    data.each do |key, value|
      html += "<dt>#{key}</dt><dd>#{value}</dd>"
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
      html += "<tr><td>#{key}</td><td>#{value}</td></tr>"
    end
    html += '</table>'
    raw(html)
  end

  ##
  # @param entity [Item] or some other object suitable for passing
  # to `icon_for`
  # @param size [Integer] One of the sizes in `Derivable::IMAGE_DERIVATIVES`
  # @param shape [String] One of the `Bytestream::Shape` constants
  # @return [String]
  #
  def thumbnail_tag(entity, size, shape = Bytestream::Shape::ORIGINAL)
    html = ''
    if entity.kind_of?(Item)
      url = image_url(entity, size)
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
  #
  def viewer_for(item)
    if item.is_pdf?
      return pdf_viewer_for(item)
    elsif item.is_image?
      return image_viewer_for(item)
    elsif item.is_audio?
      return audio_player_for(item)
    elsif item.is_text?
      # We don't provide a viewer for text as this is handled separately in
      # show-item view by reading the item's full_text property. Full text and
      # a viewer are not mutually exclusive -- an image may have full text, an
      # audio clip may have a transcript, etc.
    elsif item.is_video?
      return video_player_for(item)
    end
    nil
  end

  private

  def audio_player_for(item)
    bs = item.bytestreams.select{ |bs| bs.type == Bytestream::Type::ACCESS_MASTER }.first
    tag = "<audio controls>
      <source src=\"#{item_access_master_bytestream_url(item)}\"
              type=\"#{bs.media_type}\">
        Your browser does not support the audio tag.
    </audio>"
    raw(tag)
  end

  ##
  # @param [Item] item
  # @param [Integer] size
  # @return [String, nil] Image URL or nil if the item is not an image
  #
  def image_url(item, size)
    if item.is_image?
      bs = item.access_master_bytestream || item.preservation_master_bytestream
      if bs.pathname
        return sprintf('%s/full/!%d,%d/0/default.jpg', iiif_url(item), size, size)
      end
    end
    nil
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
        tileSources: \"#{j(iiif_url(item))}\"
    });
    </script>"
    raw(html)
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
    type = nil
    case bytestream.type
      when Bytestream::Type::ACCESS_MASTER
        type = 'Access Master'
      when Bytestream::Type::PRESERVATION_MASTER
        type = 'Preservation Master'
    end

    format = bytestream.url ? 'External Resource' : bytestream.human_readable_name

    dimensions = nil
    if bytestream.width and bytestream.width > 0 and bytestream.height and
        bytestream.height > 0
      dimensions = "<small>#{bytestream.width}&times;#{bytestream.height}</small>"
    end

    size = bytestream.byte_size
    size = "<small>(#{number_to_human_size(size)})</small>" if size

    raw("#{type} &mdash; #{format} #{dimensions} #{size}")
  end

  def human_label_for_uri(describable, uri)
    if describable.kind_of?(Collection)
      collection = describable
    else
      collection = describable.collection
    end
    triple = collection.db_counterpart.metadata_profile.triples.
        where(predicate: uri).first
    triple ? triple.label : nil
  end

  def tech_metadata_for(item)
    data = {
        'Created' => local_time_ago(item.created),
        'Last Modified' => local_time_ago(item.last_modified),
        'Last Indexed' => local_time_ago(item.last_indexed)
    }
    url = iiif_url(item)
    data['Image Server URL'] = link_to(url, url) if url
    data
  end

end
