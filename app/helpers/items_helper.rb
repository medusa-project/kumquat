module ItemsHelper

  ##
  # @param item [Item]
  # @param options [Hash] with available keys: `:for_admin` (boolean)
  #
  def download_button(item, options = {})
    bytestreams = item.bytestreams
    return nil unless bytestreams.any?

    html = '<div class="btn-group">
      <button type="button" class="btn btn-default dropdown-toggle"
           data-toggle="dropdown" aria-expanded="false">
        <i class="fa fa-download"></i> Download <span class="caret"></span>
      </button>'
    html += '<ul class="dropdown-menu pull-right" role="menu">'
    #html += '<li>'
    #html += link_to(download_label_for_bytestream(item.master_bytestream),
    #                item_master_bytestream_url(item))
    #html += '</li>'
    #html += '<li class="divider"></li>'
    bytestreams.each do |bs|
      html += '<li>'
      url = bs.url ? bs.url : '#'
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
    raw(html)
  end

  ##
  # @param items [ActiveMedusa::Relation]
  # @param options [Hash] Options hash.
  # @option options [Boolean] :show_collection_facet
  # @option options [MetadataProfile] :metadata_profile
  #
  def facets_as_panels(items, options = {})
    return nil # TODO fix
    return nil unless items.facet_fields # nothing to do

    # get the list of facets to display from the provided metadata profile; or,
    # if not supplied, the default profile.
    profile = options[:metadata_profile] ||
        MetadataProfile.where(default: true).limit(1).first
    virtual_collection_triple = Triple.new(facet: Facet.find_by_name('Collection'),
                                           facet_label: 'Collection')
    profile_facetable_triples = [virtual_collection_triple] +
        profile.triples.where('facet_id IS NOT NULL').order(:index)

    term_limit = Option::integer(Option::Key::FACET_TERM_LIMIT)

    html = ''
    profile_facetable_triples.each do |triple|
      result_facet = items.facet_fields.
          select{ |f| f.field == triple.facet.solr_field }.first
      next unless result_facet and
          result_facet.terms.select{ |t| t.count > 0 }.any?
      next if result_facet.field == 'kq_collection_facet' and
          !options[:show_collection_facet]
      panel = "<div class=\"panel panel-default\">
      <div class=\"panel-heading\">
        <h3 class=\"panel-title\">#{triple.facet_label}</h3>
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

        if result_facet.field == 'kq_collection_facet'
          collection = Repository::Collection.find_by_uri(term.name)
          term_label = collection.title if collection
        else
          term_label = term.label
        end

        panel += "<li class=\"kq-term\">"
        panel += "<div class=\"checkbox\">"
        panel += "<label>"
        panel += "<input type=\"checkbox\" name=\"psap-facet-term\" #{checked} "\
        "data-checked-href=\"#{url_for(unchecked_params)}\" "\
        "data-unchecked-href=\"#{url_for(checked_params)}\">"
        panel += "<span class=\"kq-term-name\">#{term_label}</span> "
        panel += "<span class=\"kq-count badge\">#{term.count}</span>"
        panel += "</label>"
        panel += "</div>"
        panel += "</li>"
      end
      html += panel + '</ul></div></div>'
    end
    raw(html)
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
      html += link_to(link_target, class: 'kq-thumbnail-link') do
        if entity.kind_of?(Collection)
          #media_types = "(#{Derivable::TYPES_WITH_IMAGE_DERIVATIVES.join(' OR ')})"
          media_types = %w(image/jp2 image/jpeg image/png image/tiff).join(' OR ')
          item = Item.where("{!join from=#{Solr::Fields::PARENT_ITEM} "\
              "to=#{Solr::Fields::ID}}#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:(#{media_types})").
              filter(Solr::Fields::COLLECTION => entity.id).
              omit_entity_query(true).
              facet(false).order("random_#{SecureRandom.hex}").limit(1).first
          item ||= Collection
        else
          item = entity
        end
        raw('<div class="kq-thumbnail">' +
          thumbnail_tag(item,
                        options[:thumbnail_size] ? options[:thumbnail_size] : 256,
                        options[:thumbnail_shape]) +
        '</div>')
      end
      html += '<span class="kq-title">'
      html += link_to(entity.title, link_target)
      if options[:show_remove_from_favorites_buttons] and entity.kind_of?(Item)
        html += ' <button class="btn btn-xs btn-danger ' +
            'kq-remove-from-favorites" data-web-id="' + entity.web_id + '">'
        html += '<i class="fa fa-heart"></i> Remove'
        html += '</button>'
      end
      if options[:show_add_to_favorites_buttons] and entity.kind_of?(Item)
        html += ' <button class="btn btn-default btn-xs ' +
            'kq-add-to-favorites" data-web-id="' + entity.web_id + '">'
        html += '<i class="fa fa-heart-o"></i>'
        html += '</button>'
      end
      html += '</span>'
      if options[:show_collections] and entity.kind_of?(Item)
        html += '<br>'
        html += link_to(entity.collection) do
          raw("#{self.icon_for(entity.collection)} #{entity.collection.title}")
        end
      end
      if options[:show_description]
        html += '<br>'
        html += '<span class="kq-description">'
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
  # @param metadata_type [Integer] One of the Element::Type constants
  # @return [String]
  #
  def metadata_as_table(entity, metadata_type = Element::Type::DESCRIPTIVE)
    html = '<table class="table table-condensed kq-metadata">'
    elements = entity.metadata.select{ |e| e.type == metadata_type }
    elements.map(&:name).uniq.each do |name|
      html += '<tr>'
      html += "<td>#{name}</td>"
      html += '<td>'
      matching_elements = elements.select{ |e| e.name == name }
      if matching_elements.length > 1
        html += '<ul>'
        matching_elements.each do |element|
          html += "<li>#{element.value}</li>"
        end
        html += '</ul>'
      elsif matching_elements.length == 1
        html += matching_elements.first.value.to_s
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
    items.each do |child|
      link_target = options[:link_to_admin] ?
          admin_item_path(child) : item_path(child)
      html += '<li><div>'
      if item == child
        html += raw('<div class="kq-thumbnail">' +
            thumbnail_tag(child, 256) +
            '</div>')
        html += "<strong class=\"kq-text kq-title\">#{truncate(child.title, length: 40)}</strong>"
      else
        html += link_to(link_target) do
          raw('<div class="kq-thumbnail">' + thumbnail_tag(child, 256) + '</div>')
        end
        html += link_to(truncate(child.title, length: 40), link_target,
                        class: 'kq-title')
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
        html += '<div class="kq-thumbnail">'
        html += link_to(item_path(item)) do
          thumbnail_tag(item, 256, Bytestream::Shape::SQUARE)
        end
        html += '</div>'
        html += link_to(truncate(item.title, length: 40),
                        item_path(item), class: 'kq-title')
        html += '</li>'
      end
      html += '</ul>'
    end
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
    tag = "<audio controls>
      <source src=\"#{bytestream_url(item.master_bytestream)}\"
              type=\"#{item.master_bytestream.media_type}\">
        Your browser does not support the audio tag.
    </audio>"
    raw(tag)
  end

  ##
  # @param [Item] item
  # @return [String, nil] Base IIIF URL or nil if the item is not an image
  #
  def iiif_url(item)
    if item.is_image?
      bs = item.bytestreams.select{ |b| b.type == Bytestream::Type::ACCESS_MASTER }.first ||
          item.bytestreams.select{ |b| b.type == Bytestream::Type::PRESERVATION_MASTER }.first
      if bs.pathname
        return sprintf('%s/%s',
                       PearTree::Application.peartree_config[:iiif_url],
                       CGI.escape(bs.pathname))
      end
    end
    nil
  end

  ##
  # @param [Item] item
  # @param [Integer] size
  # @return [String, nil] Image URL or nil if the item is not an image
  #
  def image_url(item, size)
    if item.is_image?
      bs = item.bytestreams.select{ |b| b.type == Bytestream::Type::ACCESS_MASTER }.first ||
          item.bytestreams.select{ |b| b.type == Bytestream::Type::PRESERVATION_MASTER }.first
      if bs.pathname
        return sprintf('%s/full/!%d,%d/0/default.jpg', iiif_url(item), size, size)
      end
    end
    nil
  end

  def image_viewer_for(item)
    html = "<div id=\"kq-image-viewer\"></div>
    #{javascript_include_tag('/openseadragon/openseadragon.min.js')}
    <script type=\"text/javascript\">
    var viewer = OpenSeadragon({
        id: \"kq-image-viewer\",
        preserveViewport: true,
        prefixUrl: \"/openseadragon/images/\",
        tileSources: \"#{j(iiif_url(item))}\"
    });
    </script>"
    if Rails.env.development?
      html += "DEVELOPMENT: IIIF URL: #{iiif_url(item)}"
    end
    raw(html)
  end

  def pdf_viewer_for(item)
    link_to(item_master_bytestream_url(item)) do
      thumbnail_tag(item, 256)
    end
  end

  def video_player_for(item)
    tag = "<video controls id=\"kq-video-player\">
      <source src=\"#{bytestream_url(item.master_bytestream)}\"
              type=\"#{item.master_bytestream.media_type}\">
        Your browser does not support the video tag.
    </video>"
    raw(tag)
  end

  ##
  # @param [Bytestream] bytestream
  #
  def download_label_for_bytestream(bytestream)
    parts = []
    #if bytestream.type == Bytestream::Type::MASTER
    #  parts << 'Master'
    #end
    if bytestream.url
      parts << 'External Resource'
    else
      type = MIME::Types[bytestream.media_type].first
      if type and type.friendly
        parts << type.friendly
      elsif bytestream.media_type.present?
        parts << bytestream.media_type
      end
      if bytestream.width and bytestream.width > 0 and bytestream.height and
          bytestream.height > 0
        parts << "<small>#{bytestream.width}&times;#{bytestream.height}</small>"
      end
      #if bytestream.byte_size
      #  parts << "<small>#{number_to_human_size(bytestream.byte_size)}</small>"
      #end
    end
    raw(parts.join(' | '))
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

end
