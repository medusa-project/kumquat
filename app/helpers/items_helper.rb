module ItemsHelper

  DEFAULT_THUMBNAIL_SIZE = 256
  PAGE_TITLE_LENGTH = 35

  ##
  # @param bs [Bytestream]
  # @param options [Hash<Symbol,Object>]
  # @option options [Boolean] :admin
  # @return [String]
  #
  def bytestream_metadata_as_table(bs, options = {})
    data = bytestream_metadata_for(bs, options)
    html = ''
    if data.any?
      categories = data.map{ |f| f[:category] }.uniq.
          reject{ |cat| cat == 'ExifTool' }

      # create the category tabs
      html += '<ul class="nav nav-pills" role="tablist">'
      categories.each_with_index do |category, index|
        tab_id = "pt-metadata-tab-#{bs.bytestream_type}-#{category.gsub(' ', '')}"
        class_ = (index == 0) ? 'active' : ''
        html += "<li role=\"presentation\" class=\"#{class_}\">
          <a href=\"##{tab_id}\" aria-controls=\"#{tab_id}\"
              role=\"tab\" data-toggle=\"tab\">#{category}</a>
        </li>"
      end
      html += '</ul>'

      # create the category tab panes
      html += '<div class="tab-content">'
      categories.each_with_index do |category, index|
        tab_id = "pt-metadata-tab-#{bs.bytestream_type}-#{category.gsub(' ', '')}"
        class_ = (index == 0) ? 'active' : ''
        html += "<div role=\"tabpanel\" class=\"tab-pane #{class_}\"
            id=\"#{tab_id}\">"

        html += '<table class="table table-condensed pt-metadata">'
        data.select{ |row| row[:category] == category }.each do |row|
          if row[:value].respond_to?(:each)
            value = '<ul>'
            row[:value].each do |v|
              value += "<li>#{v}</li>"
            end
            value += '</ul>'
          else
            value = row[:value]
          end

          html += "<tr>
            <td>#{row[:label]}</td>
            <td>#{raw(value)}</td>
          </tr>"
        end
        html += '</table>'

        html += "</div>" # .tab-pane
      end
      html += '</div>' # .tab-content
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
    collection_element = MetadataProfileElement.new(name: 'collection',
                                                    facetable: true)
    profile_facetable_elements = [collection_element] +
        options[:metadata_profile].elements.where(facetable: true).
            order(:index)

    html = ''
    profile_facetable_elements.each do |element|
      result_facet = items.facet_fields.
          select{ |f| f.field == element.solr_facet_field }.first
      next unless result_facet and
          result_facet.terms.select{ |t| t.count > 0 }.any?
      is_collection_facet =
          (result_facet.field == Item::SolrFields::COLLECTION + ItemElement.solr_facet_suffix)
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
      html += link_to(link_target, class: 'pt-title') do
        raw('<div class="pt-thumbnail">' +
            thumbnail_tag(child, DEFAULT_THUMBNAIL_SIZE, :square) +
          '</div>' +
          '<div class="pt-label">' +
            truncate(child.title, length: PAGE_TITLE_LENGTH) +
          '</div>')
      end
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
  # @return [String, nil] Base IIIF URL or nil if the item is not
  #                       IIIF-compatible
  #
  def iiif_item_url(item)
    url = nil
    bs = item.access_master_bytestream
    if !bs or (!bs.is_image? and !bs.is_pdf?)
      bs = item.preservation_master_bytestream
      if !bs or (!bs.is_image? and !bs.is_pdf?)
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
      html += '<h1 class="pt-title pt-compound-title">'
      if item.parent
        html += "<small>#{link_to relative_parent.title, relative_parent}</small>"
        html += "<br>&nbsp;&nbsp;&#8627; "
      end
      html += "#{icon_for(relative_child)} #{relative_child.title}</h1>"
    else
      html += "<h1 class=\"pt-title\">#{icon_for(item)} #{item.title}"
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
          admin_collection_item_path(item.collection, item) : polymorphic_path(item)
      html += '<li>'\
        '<div>'
      html += link_to(link_target, class: 'pt-thumbnail-link') do
        size = options[:thumbnail_size] ? options[:thumbnail_size] : 256
        raw('<div class="pt-thumbnail">' +
          thumbnail_tag(item.effective_representative_item, size, :square) +
        '</div>')
      end
      html += '<span class="pt-label">'
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

      if options[:show_collections] and item.collection
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
  # @param options [Hash]
  # @option options [Boolean] :admin
  # @return [String]
  # @see `tech_metadata_as_list`
  #
  def metadata_as_list(item, options = {})
    html = '<dl class="pt-metadata">'
    # iterate through the index-ordered elements in the collection's metadata
    # profile in order to display the entity's elements in the correct order
    defs = item.collection.effective_metadata_profile.elements
    defs = defs.select(&:visible) unless options[:admin]
    defs.each do |e_def|
      # These will be displayed elsewhere on the page.
      next if %w(rights title).include?(e_def.name) and !options[:admin]
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
  # @param options [Hash]
  # @option options [Boolean] :admin
  # @return [String]
  # @see `tech_metadata_as_table`
  #
  def metadata_as_table(item, options = {})
    html = '<table class="table table-condensed pt-metadata">'

    # iterate through the index-ordered elements in the collection's metadata
    # profile in order to display the entity's elements in the correct order
    defs = item.collection.effective_metadata_profile.elements
    defs = defs.select(&:visible) unless options[:admin]
    defs.each do |e_def|
      # These will be displayed elsewhere on the page.
      next if %w(rights title).include?(e_def.name) and !options[:admin]
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
  # @param item [Item]
  # @return [String]
  #
  def metadata_section(item)
    html = "<h2>Descriptive Info</h2>
         <div class=\"visible-xs\">
           #{metadata_as_list(item)}
         </div>
         <div class=\"hidden-xs\">
           #{metadata_as_table(item)}
         </div>"
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
  # @param pages [Relation<Item>]
  # @param selected_item [Item]
  # @param options [Hash] with available keys: `:link_to_admin` [Boolean]
  #
  def pages_as_list(pages, selected_item, options = {})
    return nil unless pages.any?
    html = '<ol>'
    pages.each do |page|
      link_target = options[:link_to_admin] ?
          admin_collection_item_path(page.collection, page) : item_path(page)
      html += '<li>'
      if selected_item&.repository_id == page.repository_id
        html += '<div class="pt-current">'
        html += '<div class="pt-thumbnail">' +
                    thumbnail_tag(page, DEFAULT_THUMBNAIL_SIZE, :square) +
            '</div>'
        html += '<span class=\"pt-title\">' +
            truncate(page.title, length: PAGE_TITLE_LENGTH) + '</span>'
      else
        html += '<div>'
        html += link_to(link_target) do
          raw('<div class="pt-thumbnail">' +
                  thumbnail_tag(page, DEFAULT_THUMBNAIL_SIZE, :square) + '</div>')
        end
        html += link_to(truncate(page.title, length: PAGE_TITLE_LENGTH),
                        link_target, class: 'pt-title')
        html += '</div>'
      end
      html += '</li>'
    end
    html += '</ol>'
    raw(html)
  end

  ##
  # Returns non-AJAX pagination for item results view.
  #
  # @param items [Relation]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate(items, per_page, current_page, max_links = 9)
    do_paginate(items, per_page, current_page, max_links)
  end

  ##
  # Returns AJAX pagination for files in show-item view.
  #
  # @param items [Relation]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate_files(parent_item, items, per_page, current_page, max_links = 9)
    do_paginate(items, per_page, current_page, max_links, parent_item,
                Item::Variants::FILE, true)
  end

  ##
  # Returns AJAX pagination for pages in show-item view.
  #
  # @param items [Relation]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate_pages(parent_item, items, per_page, current_page, max_links = 9)
    do_paginate(items, per_page, current_page, max_links, parent_item,
                Item::Variants::PAGE, true)
  end

  ##
  # @param item [Item]
  # @param options [Hash]
  # @option options [Boolean] :pretty_print
  # @return [String]
  #
  def schema_org_json_ld(item, options = {})
    # See: http://schema.org/CreativeWork
    # See: https://search.google.com/structured-data/testing-tool

    # N.B.: search engines allegedly do not appreciate it when this blob
    # contains information that does not appear in human-readable portions of
    # the page.

    # Base keys contained in all blobs.
    struct = {
        '@context': 'http://schema.org',
        '@type': 'CreativeWork'
    }

    ######################### Thing properties ############################

    # alternateName
    alternate_name = item.element('alternativeTitle')
    struct[:alternateName] = alternate_name.value if alternate_name

    # description
    description = item.element('description')
    struct[:description] = description.value if description

    # image
    if item.is_image? or item.is_pdf?
      # schema.org does not recommend any particular sizes, so make one up.
      # We don't want to expose a master image to search engines as it might
      # be huge and/or in a format they can't use.
      struct[:image] = {
          '@type': 'ImageObject',
          'contentUrl': item_image_url(item, 1024)
      }
    end

    # name
    name = item.element('title')
    struct[:name] = name.value if name

    # url
    struct[:url] = item_url(item)

    ###################### CreativeWork properties ########################

    # associatedMedia
    if item.bytestreams.any?
      struct[:associatedMedia] = []

      bs = item.access_master_bytestream
      if bs
        media = {}
        if bs.is_audio?
          media[:'@type'] = 'AudioObject'
        elsif bs.is_image?
          media[:'@type'] = 'ImageObject'
        elsif bs.is_video?
          media[:'@type'] = 'VideoObject'
        else
          media[:'@type'] = 'MediaObject'
        end
        media[:contentUrl] = item_access_master_bytestream_url(item)
        size = bs.byte_size
        media[:contentSize] = size if size
        media[:fileFormat] = bs.media_type
        struct[:associatedMedia] << media
      end

      bs = item.preservation_master_bytestream
      if bs
        media = {}
        if bs.is_audio?
          media[:'@type'] = 'AudioObject'
        elsif bs.is_image?
          media[:'@type'] = 'ImageObject'
        elsif bs.is_video?
          media[:'@type'] = 'VideoObject'
        else
          media[:'@type'] = 'MediaObject'
        end
        media[:contentUrl] = item_preservation_master_bytestream_url(item)
        size = bs.byte_size
        media[:contentSize] = size if size
        media[:fileFormat] = bs.media_type
        struct[:associatedMedia] << media
      end
    end

    # audience
    audience = item.element('audience')
    if audience
      struct[:audience] = {
          '@type': 'Audience',
          'audienceType': audience.value
      }
    end

    # contentLocation
    location = item.element('spatialCoverage')
    if location
      struct[:contentLocation] = {
          '@type': 'Place',
          'name': location.value
      }
      if item.latitude and item.longitude
        struct[:contentLocation][:geo] = {
            '@type': 'GeoCoordinates',
            latitude: item.latitude,
            longitude: item.longitude
        }
      end
    end

    # dateCreated
    struct[:dateCreated] = item.created_at.utc.iso8601

    # dateModified
    struct[:dateModified] = item.updated_at.utc.iso8601

    # hasPart
    if item.items.any?
      struct[:hasPart] = []
      item.items.each do |child|
        struct[:hasPart] << {
            '@type': 'CreativeWork',
            name: child.title,
            url: item_url(child)
        }
      end
    end

    # isPartOf
    if item.parent
      struct[:isPartOf] = {
          '@type': 'CreativeWork',
          name: item.parent.title,
          url: item_url(item.parent)
      }
    end

    # mainEntity
    if item.parent
      struct[:mainEntity] = {
          '@type': 'CreativeWork',
          name: item.root_parent.title,
          url: item_url(item.root_parent)
      }
    end

    # license
    statement = item.effective_rightsstatements_org_statement
    struct[:license] = statement.uri if statement

    # position
    struct[:position] = item.page_number if item.page_number

    # temporalCoverage (Google doesn't recognize)
    #struct[:temporalCoverage] = item.date.utc.iso8601 if item.date

    # text
    struct[:text] = item.full_text if item.full_text.present?

    # thumbnailUrl
    if item.is_image? or item.is_pdf?
      struct[:thumbnailUrl] = item_image_url(item, ItemsHelper::DEFAULT_THUMBNAIL_SIZE)
    end

    options[:pretty_print] ? JSON.pretty_generate(struct) : JSON.generate(struct)
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
          thumbnail_tag(item, DEFAULT_THUMBNAIL_SIZE, :square)
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
    sortable_elements = metadata_profile.elements.where(sortable: true)
    default_sortable_element = metadata_profile.default_sortable_element
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
  # @param shape [Symbol] :default or :square
  # @return [String]
  #
  def thumbnail_tag(entity, size, shape = :default)
    html = ''
    if entity.kind_of?(Bytestream)
      url = bytestream_image_url(entity, size, shape)
      if url
        # no alt because it may appear in a huge font size if the image is 404
        html += image_tag(url, alt: '')
      else
        html += icon_for(entity) # ApplicationHelper
      end
    elsif entity.kind_of?(Item)
      url = item_image_url(entity, size, shape)
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
  # @param entity [Item, Bytestream] or some other object suitable for passing
  #                                  to `icon_for`
  # @param size [Integer]
  # @param shape [Symbol] :default or :square
  # @return [String]
  #
  def thumbnail_url(entity, size, shape = :default)
    url = nil
    if entity.kind_of?(Bytestream)
      url = bytestream_image_url(entity, size, shape)
    elsif entity.kind_of?(Item)
      url = item_image_url(entity, size, shape)
    end
    url
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
    bs = item.bytestreams.select{ |bs| bs.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    url = item_access_master_bytestream_url(item, disposition: 'inline')
    unless bs
      bs = item.bytestreams.select{ |bs| bs.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
      url = item_preservation_master_bytestream_url(item, disposition: 'inline')
    end
    html = ''
    if bs
      html += "<audio src=\"#{url}\" type=\"#{bs.media_type}\" controls>
          <a href=\"#{url}\">Download audio</a>
      </audio>"
    end
    raw(html)
  end

  ##
  # @param bs [Bytestream]
  # @param size [Integer]
  # @param shape [Symbol] :default or :square
  # @return [String, nil] Image URL or nil if the item is not an image
  #
  def bytestream_image_url(bs, size, shape = :default)
    url = nil
    if (bs.is_image? or bs.is_pdf?) and bs.repository_relative_pathname
      shape = (shape == :square) ? 'square' : 'full'
      url = sprintf('%s/%s/!%d,%d/0/default.jpg',
                     iiif_bytestream_url(bs), shape, size, size)
    end
    url
  end

  ##
  # @param bytestream [Bytestream]
  # @param options [Hash<Symbol,Object>]
  # @option options [Boolean] :admin
  # @return [Array<Hash<Symbol,Object>>] Array of hashes with :label,
  #                                      :category, and :value keys.
  #
  def bytestream_metadata_for(bytestream, options = {})
    data = []
    if bytestream
      # status
      data << {
          label: 'Status',
          category: 'File',
          value: bytestream.exists? ?
              '<span class="label label-success">OK</span>' :
              '<span class="label label-danger">MISSING</span>'
      }
      if options[:admin]
        data << {
            label: 'Pathname',
            category: 'File',
            value: bytestream.absolute_local_pathname
        }
        if bytestream.cfs_file_uuid.present?
          data << {
              label: 'Medusa CFS File',
              category: 'File',
              value: link_to(bytestream.cfs_file_uuid, bytestream.medusa_url,
                             target: '_blank')
          }
        end
      end
      if bytestream.is_image?
        begin
          bytestream.metadata.each do |field|
            data << {
                label: field[:label],
                category: field[:category],
                value: field[:value].respond_to?(:each) ?
                    field[:value] : truncate(field[:value].to_s, length: 400)
            }
          end
        rescue IOError
          # Nothing we can do.
        end
      end
    end
    data
  end

  ##
  # @param item [Item]
  # @return [String, nil] Mailto string for injection into an anchor href, or
  #                       nil if the item's collection's repository does not
  #                       have a contact email.
  #
  def curator_mailto(item)
    mailto = nil
    email = item.collection.medusa_repository.email
    if email.present?
      subject = 'Feedback about a digital collections item'
      body = "Item: #{item_url(item)}%0D"
      body += "%0D"
      body += "(Enter your comment here.)%0D"
      mailto = "mailto:#{email}?subject=#{subject}&body=#{body}"
    end
    mailto
  end

  ##
  # @param items [Relation]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  # @param parent_item [Item]
  # @param child_item_variant [Item::Variant]
  # @param remote [Boolean]
  #
  def do_paginate(items, per_page, current_page, max_links = 9,
                  parent_item = nil, child_item_variant = nil, remote = false)
    return '' if items.total_length <= per_page
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

    case child_item_variant
      when Item::Variants::FILE
        first_link = link_to(item_files_path(parent_item,
                                             params.except(:start).symbolize_keys),
                             remote: remote, 'aria-label': 'First') do
          raw('<span aria-hidden="true">First</span>')
        end
        prev_link = link_to(item_files_path(parent_item,
                                            params.merge(start: prev_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Previous') do
          raw('<span aria-hidden="true">&laquo;</span>')
        end
        next_link = link_to(item_files_path(parent_item,
                                            params.merge(start: next_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Next') do
          raw('<span aria-hidden="true">&raquo;</span>')
        end
        last_link = link_to(item_files_path(parent_item,
                                            params.merge(start: last_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Last') do
          raw('<span aria-hidden="true">Last</span>')
        end
      when Item::Variants::PAGE
        first_link = link_to(item_pages_path(parent_item,
                                             params.except(:start).symbolize_keys),
                             remote: remote, 'aria-label': 'First') do
          raw('<span aria-hidden="true">First</span>')
        end
        prev_link = link_to(item_pages_path(parent_item,
                                            params.merge(start: prev_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Previous') do
          raw('<span aria-hidden="true">&laquo;</span>')
        end
        next_link = link_to(item_pages_path(parent_item,
                                            params.merge(start: next_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Next') do
          raw('<span aria-hidden="true">&raquo;</span>')
        end
        last_link = link_to(item_pages_path(parent_item,
                                            params.merge(start: last_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Last') do
          raw('<span aria-hidden="true">Last</span>')
        end
      else
        first_link = link_to(params.except(:start), remote: remote,
                             'aria-label': 'First') do
          raw('<span aria-hidden="true">First</span>')
        end
        prev_link = link_to(params.merge(start: prev_start).symbolize_keys,
                            remote: remote, 'aria-label': 'Previous') do
          raw('<span aria-hidden="true">&laquo;</span>')
        end
        next_link = link_to(params.merge(start: next_start).symbolize_keys,
                            remote: remote, 'aria-label': 'Next') do
          raw('<span aria-hidden="true">&raquo;</span>')
        end
        last_link = link_to(params.merge(start: last_start).symbolize_keys,
                            remote: remote, 'aria-label': 'Last') do
          raw('<span aria-hidden="true">Last</span>')
        end
    end

    # http://getbootstrap.com/components/#pagination
    html = '<nav>' +
        '<ul class="pagination">' +
        "<li #{current_page == first_page ? 'class="disabled"' : ''}>#{first_link}</li>" +
        "<li #{current_page == prev_page ? 'class="disabled"' : ''}>#{prev_link}</li>"
    (first_page..last_page).each do |page|
      start = (page - 1) * per_page
      case child_item_variant
        when Item::Variants::FILE
          path = (start == 0) ? item_files_path(parent_item, params.except(:start).symbolize_keys) :
              item_files_path(parent_item, params.merge(start: start).symbolize_keys)
          page_link = link_to(path, remote: remote) do
            raw("#{page} #{(page == current_page) ?
                '<span class="sr-only">(current)</span>' : ''}")
          end
        when Item::Variants::PAGE
          path = (start == 0) ? item_pages_path(parent_item, params.except(:start).symbolize_keys) :
              item_pages_path(parent_item, params.merge(start: start).symbolize_keys)
          page_link = link_to(path, remote: remote) do
            raw("#{page} #{(page == current_page) ?
                '<span class="sr-only">(current)</span>' : ''}")
          end
        else
          page_link = link_to((start == 0) ? params.except(:start) :
                                  params.merge(start: start).symbolize_keys, remote: remote) do
            raw("#{page} #{(page == current_page) ?
                '<span class="sr-only">(current)</span>' : ''}")
          end
      end
      html += "<li class=\"#{page == current_page ? 'active' : ''}\">" +
          page_link + '</li>'
    end
    html += "<li #{current_page == next_page ? 'class="disabled"' : ''}>#{next_link}</li>" +
        "<li #{current_page == last_page ? 'class="disabled"' : ''}>#{last_link}</li>"
    html += '</ul>' +
        '</nav>'
    raw(html)
  end

  ##
  # @param bs [Bytestream]
  # @return [Boolean] Whether the given bytestream is presumed safe to feed to
  #                   an IIIF server (won't bog it down too much).
  #
  def iiif_safe?(bs)
    max_size = 30000000 # arbitrary

    return false if !bs or bs.repository_relative_pathname.blank?

    # Large TIFF preservation masters are probably neither tiled nor
    # multiresolution, so are going to be very inefficient to read.
    if bs.bytestream_type == Bytestream::Type::PRESERVATION_MASTER and
        bs.media_type == 'image/tiff'
      begin
        return false if File.size(bs.absolute_local_pathname) > max_size
      rescue
        return false
      end
    end
    true
  end

  def image_viewer_for(item)
    html = ''

    # If there is no access master, and the preservation master is too large,
    # render an alert instead of the viewer.
    if !item.access_master_bytestream and
        !iiif_safe?(item.preservation_master_bytestream)
      html += '<div class="alert alert-info">Preservation master image is too
          large to display, and no access master is available.</div>'
    else
      # https://openseadragon.github.io/docs/OpenSeadragon.html#.Options
      html += "<div id=\"pt-image-viewer\"></div>
      #{javascript_include_tag('/openseadragon/openseadragon.min.js')}
      <script type=\"text/javascript\">
      OpenSeadragon.setString('Tooltips.Home', 'Reset');
      OpenSeadragon.setString('Tooltips.ZoomIn', 'Zoom In');
      OpenSeadragon.setString('Tooltips.ZoomOut', 'Zoom Out');
      OpenSeadragon.setString('Tooltips.FullPage', 'Full Screen');
      OpenSeadragon.setString('Tooltips.RotateLeft', 'Rotate Left');
      OpenSeadragon.setString('Tooltips.RotateRight', 'Rotate Right');
      OpenSeadragon({
          id: \"pt-image-viewer\",
          showNavigator: true,
          showRotationControl: true,
          navigatorSizeRatio: 0.2,
          controlsFadeDelay: 1000,
          controlsFadeLength: 1000,
          immediateRender: true,
          preserveViewport: true,
          prefixUrl: \"/openseadragon/images/\",
          tileSources: \"#{j(iiif_item_url(item))}\"
      });
      </script>"
    end
    raw(html)
  end

  ##
  # @param item [Item]
  # @param size [Integer]
  # @param shape [Symbol] :default or :square
  # @return [String, nil] Image URL or nil if the item is not an image
  #
  def item_image_url(item, size, shape = :default)
    url = nil
    if item.is_image? or item.is_pdf?
      bs = item.access_master_bytestream || item.preservation_master_bytestream
      if bs.repository_relative_pathname and iiif_safe?(bs)
        shape = (shape == :square) ? 'square' : 'full'
        url = sprintf('%s/%s/!%d,%d/0/default.jpg',
                      iiif_item_url(item), shape, size, size)
      end
    end
    url
  end

  def pdf_viewer_for(item)
    bs = item.bytestreams.select{ |bs| bs.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    url = item_access_master_bytestream_url(item, disposition: 'inline')
    unless bs
      bs = item.bytestreams.select{ |bs| bs.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
      url = item_preservation_master_bytestream_url(item, disposition: 'inline')
    end

    html = '<div id="pt-pdf-viewer">'
    if bs
      viewer_url = asset_path('/pdfjs/web/viewer.html?file=' + url)
      html += link_to(viewer_url, target: '_blank') do
        thumbnail_tag(item, DEFAULT_THUMBNAIL_SIZE)
      end
      html += link_to(viewer_url, target: '_blank',
                      class: 'btn btn-lg btn-success') do
        content_tag(:span, '', class: 'fa fa-file-pdf-o') + ' Open in PDF Viewer'
      end
    end
    html += '</div>'
    raw(html)
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
    dimensions = nil
    size = bytestream.byte_size
    size = "(#{number_to_human_size(size)})" if size
    raw("#{bytestream.human_readable_name} #{dimensions} #{size}")
  end

  def tech_metadata_for(item)
    data = {}
    data['Ingested'] = local_time_ago(item.created_at)
    data['Last Modified'] = local_time_ago(item.updated_at)
    data
  end

end
