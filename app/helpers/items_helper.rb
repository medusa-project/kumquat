module ItemsHelper

  DEFAULT_THUMBNAIL_SIZE = 256
  PAGE_TITLE_LENGTH      = 35
  VIEWER_HEIGHT          = '600px'
  VIEWER_WIDTH           = '95%'

  ##
  # @param binary [Binary]
  # @param options [Hash<Symbol,Object>]
  # @option options [String] :region
  # @option options [String] :size
  # @option options [Integer] :rotation
  # @option options [String] :color
  # @option options [String] :content_disposition
  # @option options [String] :filename
  # @option options [Boolean] :cache
  # @return [String, nil] Image URL, or nil if the binary is not compatible
  #                       with the image server or safe for it to serve.
  #
  def binary_image_url(binary, options = {})
    url = nil
    query = {}

    if binary.image_server_safe?
      options[:region] = 'full' if options[:region].blank?
      if options[:size].blank?
        options[:size] = 'full'
      elsif options[:size].to_i == options[:size]
        options[:size] = "!#{options[:size]},#{options[:size]}"
      end
      options[:rotation] = 0 if options[:rotation].blank?
      options[:color] = 'default' if options[:color].blank?
      options[:format] = 'jpg' if options[:format].blank?

      url = sprintf('%s/%s/%s/%d/%s.%s',
                    binary.iiif_image_url,
                    options[:region],
                    options[:size],
                    options[:rotation],
                    options[:color],
                    options[:format])

      if options[:content_disposition].present?
        if options[:content_disposition] == 'attachment'
          if options[:filename].present?
            filename = options[:filename]
          else
            filename = File.basename(binary.filename, File.extname(binary.filename)) +
                '.' + options[:format]
          end
          value = "attachment; filename=\"#{filename}\""
        else
          value = options[:content_disposition]
        end
        query['response-content-disposition'] = value
      end

      if options.keys.include?(:cache) and !options[:cache]
        query['cache'] = 'false'
      end
    end

    url += '?' + query.to_query if query.keys.any?
    url
  end

  ##
  # @param binary [Binary]
  # @param options [Hash<Symbol,Object>]
  # @option options [Boolean] :admin
  # @return [String]
  #
  def binary_metadata_as_table(binary, options = {})
    data = binary_metadata_for(binary, options)
    html = StringIO.new
    if data.any?
      categories = data.map{ |f| f[:category] }.uniq.
          reject{ |cat| cat == 'ExifTool' }

      # create the category tabs
      html << '<ul class="nav nav-tabs" role="tablist">'
      categories.each_with_index do |category, index|
        tab_id = "dl-metadata-tab-#{binary.master_type}-#{category.gsub(' ', '')}"
        class_ = (index == 0) ? 'active' : ''
        html << "<li role=\"presentation\" class=\"nav-item\">"
        html <<   "<a href=\"##{tab_id}\" class=\"nav-link #{class_}\" "\
            "aria-controls=\"#{tab_id}\" role=\"tab\" "\
            "data-toggle=\"tab\">#{category}</a>"
        html << '</li>'
      end
      html << '</ul>'

      # create the category tab panes
      html << '<div class="tab-content">'
      categories.each_with_index do |category, index|
        tab_id = "dl-metadata-tab-#{binary.master_type}-#{category.gsub(' ', '')}"
        class_ = (index == 0) ? 'active' : ''
        html << "<div role=\"tabpanel\" class=\"tab-pane #{class_}\"
            id=\"#{tab_id}\">"

        html << '<table class="table table-sm dl-metadata">'
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

          html << '<tr>'
          html <<   '<td>'
          html <<     row[:label]
          html <<   '</td>'
          html <<   '<td>'
          html <<     raw(value)
          html <<   '</td>'
          html << '</tr>'
        end
        html << '</table>'

        html << '</div>' # .tab-pane
      end
      html << '</div>' # .tab-content
    end
    raw(html.string)
  end

  ##
  # @param item [Item] Compound object
  #
  def compound_object_binary_info_table(item)
    binaries = item.binaries
    subitems = item.finder.to_a
    html = StringIO.new
    if subitems.any? or binaries.any?
      html << '<table class="table">'
      html <<   '<tr>'
      html <<     '<th>Item</th>'
      html <<     '<th>Master Type</th>'
      html <<     '<th>Category</th>'
      html <<     '<th>Filename</th>'
      html <<   '</tr>'
      binaries.each do |binary|
        html << '<tr>'
        html <<   "<td>#{item.title}</td>"
        html <<   "<td>#{binary.human_readable_master_type}</td>"
        html <<   "<td>#{binary.human_readable_media_category}</td>"
        html <<   "<td>#{link_to(binary.filename, binary.medusa_url, target: '_blank')}</td>"
        html << '</tr>'
      end
      subitems.each do |subitem|
        subitem.binaries.each_with_index do |bs, index|
          html << '<tr>'
          if index == 0
            html <<   "<td rowspan=\"#{subitem.binaries.length}\">#{subitem.title}</td>"
          end
          html <<   "<td>#{bs.human_readable_master_type}</td>"
          html <<   "<td>#{bs.human_readable_media_category}</td>"
          html <<   "<td>#{link_to(bs.filename, bs.medusa_url, target: '_blank')}</td>"
          html << '</tr>'
        end
      end
      html << '</table>'
    end
    raw(html.string)
  end

  ##
  # @param files [Enumerable<Item>]
  #
  def files_as_list(files)
    return nil unless files.any?
    html = StringIO.new
    html << '<ol>'
    files.each do |child|
      html << '<li>'
      html << link_to(item_path(child), class: 'dl-title') do
        thumb = StringIO.new
        thumb << '<div class="dl-thumbnail">'
        thumb <<   thumbnail_tag(child, shape: :square)
        thumb << '</div>'
        thumb << "<div class=\"dl-label\" title=\"#{child.title}\">"
        thumb <<   truncate(child.title, length: PAGE_TITLE_LENGTH)
        thumb << '</div>'
        raw(thumb.string)
      end
      html << '</li>'
    end
    html << '</ol>'
    raw(html.string)
  end

  ##
  # @param item [Item, nil]
  # @return [Boolean]
  #
  def has_viewer?(item)
    return false unless item
    # This logic needs to be kept in sync with viewer_for_item().
    if item.embed_tag.present? or item.is_compound?
      return true
    end
    item.effective_viewer_binary ? true : false
  end

  ##
  # @return [String]
  #
  def item_filter_field
    html = StringIO.new
    html << '<div class="input-group">'
    html <<   '<div class="input-group-prepend">'
    html <<     '<span class="input-group-text">'
    html <<       '<i class="fa fa-filter"></i>'
    html <<     '</span>'
    html <<   '</div>'
    html <<   search_field_tag(:q, params[:q], class: 'form-control',
                               placeholder: 'Filter')
    html << '</div>'
    raw(html.string)
  end

  ##
  # @param metadata_profile [MetadataProfile]
  # @return [String] HTML select menu.
  #
  def item_filter_field_element_menu(metadata_profile)
    html = StringIO.new
    html << '<select class="custom-select" name="df">'
    html <<   '<optgroup label="System Fields">'
    html <<     "<option value=\"#{Item::IndexFields::REPOSITORY_ID}\">ID</option>"
    html <<   '</optgroup>'
    html <<   '<optgroup label="Metadata Profile Elements">'
    html <<     "<option value=\"#{Item::IndexFields::SEARCH_ALL}\" selected>Any Element</option>"
    metadata_profile.elements.select(&:searchable).each do |e|
      html <<   "<option value=\"#{e.indexed_field}\">#{e.label}</option>"
    end
    html <<   '</optgroup>'
    html << '</select>'
    raw(html.string)
  end

  ##
  # Returns an IIIF Image API 2.1 URL for an item.
  #
  # @param item [Item]
  # @param region [Symbol] `:full` or `:square`
  # @param size [Symbol,Integer] Bounding box size or `:full`
  # @param format [Symbol] One of the formats allowed by the Image API.
  # @return [String, nil] Image URL, or nil if the item has no image server-
  #                       compatible image binary.
  #
  def item_image_url(item, region = :full, size = :full, format = :jpg)
    url = nil
    bin = item.effective_image_binary
    if bin
      region = (region == :square) ? 'square' : 'full'
      size = (size == :full) ? 'full' : "!#{size},#{size}" # fit within a `size` box
      time = ''
      if bin.duration.present?
        # ?time=hh:mm:ss is a nonstandard argument supported only by
        # Cantaloupe's FfmpegProcessor. All other processors will ignore it.
        # If it's missing, the first frame will be returned.
        #
        # For videos of all lengths, the time needs to be enough to advance
        # past title frames but not longer than the duration. It would be
        # easier to hard-code something like 00:00:10, but there are actually
        # some videos in the repository that are two seconds long.
        # FfmpegProcessor doesn't allow a percentage argument because ffprobe
        # doesn't. (DLD-102)
        seconds = bin.duration * 0.2
        time = '?time=' + TimeUtil.seconds_to_hms(seconds)
      end
      url = sprintf('%s/%s/%s/0/default.%s%s',
                    bin.iiif_image_url, region, size, format, time)
    end
    url
  end

  ##
  # Requested in DLD-116.
  #
  # @param item [Item]
  # @return [String]
  # @see [Getting Started With Cards](https://developer.twitter.com/en/docs/tweets/optimize-with-cards/guides/getting-started)
  # @see [Open Graph Protocol](http://ogp.me)
  # @see [Facebook Sharing Best Practices](https://developers.facebook.com/docs/sharing/best-practices)
  #
  def item_meta_tags(item)
    # N.B.: Minimum Twitter image size is 300x157 and maximum size is
    # 4096x4096 / 5MB.
    image_url = item_image_url(item, :full, 1600)

    html = StringIO.new

    # Twitter tags
    html << sprintf(
        '<meta name="twitter:card" content="%s"/>
        <meta name="twitter:title" content="%s" />
        <meta name="twitter:description" content="%s" />',
        image_url ? 'summary_large_image' : 'summary',
        truncate(item.title, length: 70),
        truncate(item.description, length: 200))
    if image_url
      html << "\n"
      html << sprintf('<meta name="twitter:image" content="%s" />',
                      image_url)
    end

    # OpenGraph tags, used by Facebook, but Twitter also falls back to them
    html << "\n"
    html << sprintf(
        '<meta property="og:title" content="%s" />
        <meta property="og:type" content="website" />
        <meta property="og:url" content="%s" />
        <meta property="og:description" content="%s" />
        <meta property="og:site_name" content="%s" />',
        item.title,
        item_url(item),
        item.description,
        Option::string(Option::Keys::WEBSITE_NAME))

    # N.B.: Minimum Facebook image size is 200x200, but they recommend at
    # least 1200x630. Images may be up to "8Mb".
    if image_url
      html << "\n"
      html << sprintf(
          '<meta property="og:image" content="%s" />
          <meta property="og:image:type" content="image/jpeg" />
          <meta property="og:image:alt" content="%s" />',
          image_url, item.title)
    end
    raw(html.string)
  end

  ##
  # @param item [Item]
  # @return [String] HTML string
  #
  def item_page_title(item)
    html = StringIO.new
    if item.collection.free_form?
      html << '<h1 class="dl-title">'
      html <<   icon_for(item)
      html <<   ' '
      html <<   item.title
      html << '</h1>'
    elsif item.parent or item.items.any?
      relative_parent = item.parent ? item.parent : item
      relative_child  = item.parent ? item : relative_parent
      html << '<h1 class="dl-title dl-compound-title">'
      if item.parent
        html << '<small>'
        html <<   link_to(relative_parent.title, relative_parent)
        html << '</small>'
        html << '<br>'
        html << '&nbsp;&nbsp;&#8627; '
      end
      html <<   icon_for(relative_child)
      html <<   ' '
      html <<   relative_child.title
      html << '</h1>'
    else
      html << '<h1 class="dl-title">'
      html <<   icon_for(item)
      html <<   ' '
      html <<   item.title
      if item.subtitle
        html <<   '<br>'
        html <<   '<small>'
        html <<     item.subtitle
        html <<   '</small>'
      end
      html << '</h1>'
    end
    raw(html.string)
  end

  ##
  # @param items [Enumerable<Representable>]
  # @return [String]
  #
  def items_as_flex(items)
    # needs to be kept in sync with the width defined in agents.js
    thumb_width = 300
    html = StringIO.new
    items.each do |item|
      html << '<div class="dl-object">'
      html <<   link_to(item) do
        thumb = StringIO.new
        thumb << '<div class="dl-thumbnail">'
        thumb <<   thumbnail_tag(item.effective_representative_entity, size: thumb_width)
        thumb << '</div>'
        raw(thumb.string)
      end
      html <<   '<h4 class="dl-title">'
      html <<      link_to(item.title, item)
      html <<   '</h4>'
      html << '</div>'
    end
    raw(html.string)
  end

  ##
  # @param item [Item]
  # @param options [Hash]
  # @option options [Boolean] :admin
  # @return [String] HTML definition list containing item metadata.
  # @see metadata_as_table
  #
  def metadata_as_list(item, options = {})
    html = StringIO.new
    html << '<dl class="dl-metadata">'
    # iterate through the index-ordered elements in the collection's metadata
    # profile in order to display the entity's elements in the correct order
    defs = item.collection.effective_metadata_profile.elements
    defs = defs.select(&:visible) unless options[:admin]
    defs.each do |e_def|
      elements = item.elements.
          select{ |e| e.name == e_def.name and (e.value.present? or e.uri.present?) }
      next if elements.empty?
      html << '<dt>'
      html <<   e_def.label
      html << '</dt>'
      html << '<dd>'
      if elements.length == 1
        html << metadata_value_for_element(elements.first, e_def.searchable)
      else
        html << '<ul>'
        elements.each do |element|
          html << '<li>'
          html <<   metadata_value_for_element(element, e_def.searchable)
          html << '</li>'
        end
        html << '</ul>'
      end
      html << '</dd>'
    end

    # Add a synthetic "collection" element.
    collection_title = item.collection&.title
    if collection_title
      html << '<dt>Collection</dt>'
      html << '<dd>'
      html <<   link_to(collection_title, item.collection)
      html << '</dd>'
    end

    html << '</dl>'
    raw(html.string)
  end

  ##
  # @param item [Item]
  # @param options [Hash]
  # @option options [Boolean] :admin
  # @return [String] HTML table containing item metadata.
  # @see metadata_as_list
  # @see tech_metadata_as_table
  #
  def metadata_as_table(item, options = {})
    html = StringIO.new
    html << '<table class="table table-sm dl-metadata">'
    # iterate through the index-ordered elements in the item's collection's
    # metadata profile.
    p_els = item.collection.effective_metadata_profile.elements
    p_els = p_els.select(&:visible) unless options[:admin]
    p_els.each do |pel|
      elements = item.elements.
          select{ |e| e.name == pel.name and (e.value.present? or e.uri.present?) }
      next if elements.empty?
      html << '<tr>'
      html <<   '<td>'
      html <<     pel.label
      html <<   '</td>'
      html << '<td>'
      if elements.length == 1
        html << metadata_value_for_element(elements.first, pel.searchable)
      else
        html << '<ul>'
        elements.each do |element|
          html << '<li>'
          html << raw(metadata_value_for_element(element, pel.searchable))
          html << '</li>'
        end
        html << '</ul>'
      end
      html <<   '</td>'
      html << '</tr>'
    end

    # Add a synthetic "collection" element.
    collection_title = item.collection&.title
    if collection_title
      html << '<tr>'
      html <<   '<td>Collection</td>'
      html <<   '<td>'
      html <<     link_to(collection_title, item.collection)
      html <<   '</td>'
      html << '</tr>'
    end

    html << '</table>'
    raw(html.string)
  end

  ##
  # @param item [Item]
  # @return [String]
  #
  def metadata_section(item)
    # Bootstrap display utilities don't work very well within collapses, so we
    # need two separate collapses here.
    html = StringIO.new
    html << '<div class="d-sm-none">'
    html <<   '<h2>'
    html <<     '<a role="button" data-toggle="collapse" href="#dl-metadata-list" aria-expanded="true" aria-controls="dl-metadata-list">'
    html <<       'Descriptive Information'
    html <<     '</a>'
    html <<   '</h2>'
    html <<   '<div id="dl-metadata-list" class="collapse show">'
    html <<     metadata_as_list(item)
    html <<   '</div>'
    html << '</div>'

    html << '<div class="d-none d-sm-block">'
    html <<   '<h2>'
    html <<     '<a role="button" data-toggle="collapse" href="#dl-metadata-table" aria-expanded="true" aria-controls="dl-metadata-table">'
    html <<       'Descriptive Information'
    html <<     '</a>'
    html <<   '</h2>'
    html <<   '<div id="dl-metadata-table" class="collapse show">'
    html <<     metadata_as_table(item)
    html <<   '</div>'
    html << '</div>'
    raw(html.string)
  end

  ##
  # Returns item pagination for agent view.
  #
  # @param agent [Agent]
  # @param count [Integer]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate_agent_items(agent, count, per_page, current_page, max_links = 9)
    do_paginate(count, per_page, current_page, max_links, agent,
                :agent_item)
  end

  ##
  # Returns pagination for item results view.
  #
  # @param count [Integer]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate_items(count, per_page, current_page, max_links = 9)
    do_paginate(count, per_page, current_page, max_links)
  end

  ##
  # Returns what the user is searching for.
  #
  # @param q [String] From params
  # @param fq [Enumerable<String>] From params
  # @param profile [MetadataProfile]
  # @return [String]
  #
  def query_summary(q, fq, profile)
    query = StringIO.new
    if fq&.any? or q.present?
      query << '<ul class="dl-query-summary">'
      if q.present?
        query << "<li>Filter: <span class=\"dl-query-summary-value\">\"#{h(q)}\"</span></li>"
      end
      fq&.each do |fq_|
        parts = fq_.split(':')
        if parts.length == 2
          name = EntityElement.element_name_for_indexed_field(parts[0])
          label = profile.elements.select{ |e| e.name == name }.first.label
          value = parts[1].chomp('"').reverse.chomp('"').reverse

          query << "<li>#{label}: <span class=\"dl-query-summary-value\">#{value}</span></li>"
        end
      end
      query << '</ul>'
    end
    raw(query.string)
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
    iiif_image_binary = item.effective_image_binary
    if iiif_image_binary
      # schema.org does not recommend any particular sizes, so make one up.
      # We don't want to expose a master image to search engines as it might
      # be huge and/or in a format they can't use.
      struct[:image] = {
          '@type': 'ImageObject',
          'contentUrl': item_image_url(item, :default, 1024)
      }
    end

    # name
    name = item.element('title')
    struct[:name] = name.value if name

    # url
    struct[:url] = item_url(item)

    ###################### CreativeWork properties ########################

    # associatedMedia
    if item.binaries.any?
      struct[:associatedMedia] = []

      item.binaries.each do |binary|
        media = {}
        if binary.is_audio?
          media[:'@type'] = 'AudioObject'
        elsif binary.is_image?
          media[:'@type'] = 'ImageObject'
        elsif binary.is_video?
          media[:'@type'] = 'VideoObject'
        else
          media[:'@type'] = 'MediaObject'
        end
        media[:contentUrl] = binary_url(binary)
        size = binary.byte_size
        media[:contentSize] = size if size
        media[:fileFormat] = binary.media_type
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
      root_parent = item.all_parents.last
      struct[:mainEntity] = {
          '@type': 'CreativeWork',
          name: root_parent.title,
          url: item_url(root_parent)
      }
    end

    # license
    statement = item.effective_rightsstatements_org_statement
    struct[:license] = statement.uri if statement

    # position
    struct[:position] = item.page_number if item.page_number

    # temporalCoverage (Google doesn't recognize)
    #struct[:temporalCoverage] = item.date.utc.iso8601 if item.date

    # thumbnailUrl
    if iiif_image_binary
      struct[:thumbnailUrl] = item_image_url(item, :default,
                                             ItemsHelper::DEFAULT_THUMBNAIL_SIZE)
    end

    options[:pretty_print] ? JSON.pretty_generate(struct) : JSON.generate(struct)
  end

  ##
  # Returns the status of a search or browse action, e.g. "Showing n of n
  # items".
  #
  # @param total_num_results [Integer]
  # @param start [Integer]
  # @param num_results_shown [Integer]
  # @return [String]
  #
  def search_status(total_num_results, start, num_results_shown)
    last = [total_num_results, start + num_results_shown].min
    raw(sprintf("Showing %d&ndash;%d of %s items",
                start + 1, last,
                number_with_delimiter(total_num_results)))
  end

  ##
  # @param entity [Item, Agent]
  # @return [String] HTML string
  #
  def share_button(entity)
    title = CGI::escape(entity.respond_to?(:title) ? entity.title : entity.name)
    url = CGI::escape(polymorphic_url(entity))

    html = StringIO.new
    html << '<div class="btn-group" role="group">
      <button type="button" class="btn btn-light dropdown-toggle"
            data-toggle="dropdown" aria-haspopup="false" aria-expanded="false">
        <i class="fa fa-share-alt"></i> Share <span class="caret"></span>
      </button>
      <div class="dropdown-menu">'
    # cite
    if entity.kind_of?(Item)
      html << link_to('#', onclick: 'return false;', class: 'dropdown-item',
                      data: { toggle: 'modal', target: '#dl-cite-modal' }) do
        raw('<i class="fas fa-pen-square"></i> Cite')
      end
      html << '<div class="dropdown-divider"></div>'
    end
    # email
    html << link_to("mailto:?subject=#{title}&body=#{url}", class: 'dropdown-item') do
      raw('<i class="fa fa-envelope"></i> Email')
    end
    html << '<div class="dropdown-divider"></div>'
    # facebook
    html << link_to("https://www.facebook.com/sharer/sharer.php?u=#{url}",
                    class: 'dropdown-item', target: '_blank') do
      raw('<i class="fab fa-facebook-square"></i> Facebook')
    end
    # twitter: https://dev.twitter.com/web/tweet-button/web-intent
    html << link_to("https://twitter.com/intent/tweet?url=#{url}&text=#{truncate(title, length: 140)}",
                    class: 'dropdown-item', target: '_blank') do
      raw('<i class="fab fa-twitter-square"></i> Twitter')
    end
    # pinterest
    url = "http://pinterest.com/pin/create/button/?url=#{url}&description=#{title}"
    if entity.kind_of?(Item)
      iiif_url = item_image_url(entity, :default, 512)
      if iiif_url
        url << "&media=#{CGI::escape(iiif_url)}"
      end
    end

    html << link_to(url, target: '_blank', class: 'dropdown-item') do
      raw('<i class="fab fa-pinterest-square"></i> Pinterest')
    end
    html <<   '</div>'
    html << '</div>'
    raw(html.string)
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

    html = StringIO.new
    if sortable_elements.any?
      html << '<form class="form-inline" method="get">'
      html <<   '<div class="form-group">'
      html <<     '<select name="sort" class="custom-select">'
      unless default_sortable_element
        html <<     '<option value="">Sort by Relevance</option>'
      end

      # If there is an element in the ?sort= query, select that. Otherwise,
      # select the metadata profile's default sort element.
      selected_element = sortable_elements.
          select{ |e| e.indexed_sort_field == params[:sort] }.first
      if !selected_element and default_sortable_element
        selected_element =
            sortable_elements.find_by_name(default_sortable_element.name)
      end
      sortable_elements.each do |e|
        selected = (e == selected_element) ? 'selected' : ''
        html << "<option value=\"#{e.indexed_sort_field}\" #{selected}>"
        html <<   "Sort by #{e.label}"
        html << '</option>'
      end
      html <<     '</select>'
      html <<   '</div>'
      html << '</form>'
    end
    raw(html.string)
  end

  ##
  # @param item [Item]
  # @return [String]
  # @see metadata_as_table
  #
  def tech_metadata_as_table(item)
    data = tech_metadata_for(item)
    html = StringIO.new
    html << '<table class="table table-sm dl-metadata">'
    data.each do |key, value|
      html << '<tr>'
      html <<   "<td>#{raw(key)}</td>"
      html <<   "<td>#{raw(value)}</td>"
      html << '</tr>'
    end
    html << '</table>'
    raw(html.string)
  end

  ##
  # @param entity [Object]
  # @param options [Hash]
  # @option options [Integer] :size Defaults to {DEFAULT_THUMBNAIL_SIZE}.
  # @option options [Symbol] :shape `:default` or `:square`; defaults to
  #                                 `:default`.
  # @option options [Boolean] :lazy If true, the `data-src` attribute will be
  #                                 set instead of `src`; defaults to false.
  # @return [String]
  #
  def thumbnail_tag(entity, options = {})
    options         = {} unless options.kind_of?(Hash)
    options[:size]  = DEFAULT_THUMBNAIL_SIZE unless options.keys.include?(:size)
    options[:shape] = 'full' unless options.keys.include?(:shape)
    options[:lazy]  = false unless options.keys.include?(:lazy)

    url = nil
    if entity.kind_of?(Binary) and entity.image_server_safe?
      url = binary_image_url(entity,
                             region: options[:shape],
                             size: options[:size])
    elsif entity.kind_of?(Collection)
      bin = entity.effective_representative_image_binary
      if bin&.image_server_safe?
        url = binary_image_url(bin,
                               region: options[:shape],
                               size: options[:size])
      end
    elsif entity.kind_of?(Item) and entity.effective_image_binary&.image_server_safe?
      url = item_image_url(entity,
                           options[:shape],
                           options[:size])
    end

    html = StringIO.new
    if url
      # No alt because it may appear in a huge font size if the image is 404.
      if options[:lazy]
        html << lazy_image_tag(url, class: 'dl-thumbnail', alt: '')
      else
        html << image_tag(url, class: 'dl-thumbnail', alt: '')
      end
    else
      html << icon_for(entity) # ApplicationHelper
    end
    raw(html.string)
  end

  ##
  # @param entity [Item, Binary] or some other object suitable for passing to
  #                              {ApplicationHelper#icon_for}
  # @param size [Integer]
  # @param shape [Symbol] `:default` or `:square`
  # @return [String]
  #
  def thumbnail_url(entity, size = DEFAULT_THUMBNAIL_SIZE, shape = :default)
    url = nil
    if entity.kind_of?(Binary)
      url = binary_image_url(entity, region: shape, size: size)
    elsif entity.kind_of?(Item)
      url = item_image_url(entity, shape, size)
    end
    url
  end

  ##
  # Returns a viewer for the given binary.
  #
  # **Does not work for 3D model binaries.**
  #
  # @param binary [Binary]
  # @return [String] HTML string
  #
  def viewer_for_binary(binary)
    if binary.is_pdf?
      return pdf_viewer_for(binary)
    elsif binary.is_audio?
      return audio_player_for(binary)
    elsif binary.is_video?
      return video_player_for(binary)
    elsif binary.is_text?
      return text_viewer_for(binary)
    end
    nil
  end

  ##
  # Returns a viewer for the given item.
  #
  # @param item [Item]
  # @return [String] HTML string
  #
  def viewer_for_item(item)
    # This logic needs to be kept in sync with has_viewer?().
    return nil unless item
    if item.embed_tag.present?
      # Replace hard-coded width/height attribute values.
      frag = Nokogiri::HTML::DocumentFragment.parse(item.embed_tag)
      frag.xpath('.//@width').remove
      frag.xpath('.//@height').remove
      # These must be kept in sync with the viewer CSS dimensions.
      frag.xpath('.//*').first['width'] = '100%'
      frag.xpath('.//*').first['height'] = '600'
      return raw(frag.to_html.strip)
    elsif item.file?
      return free_form_viewer_for(item)

      # IMET-473: image files should be presented in the same manner as compound
      # objects, with a gallery viewer showing all of the other images in the
      # same directory.
    elsif item.file? and
        item.effective_image_binary&.media_category == Binary::MediaCategory::IMAGE
      return compound_viewer_for(item.parent, item)
    elsif item.is_compound?
      return compound_viewer_for(item)
    else
      binary = item.effective_viewer_binary
      case binary&.media_category
        when Binary::MediaCategory::AUDIO
          return audio_player_for(binary)
        when Binary::MediaCategory::DOCUMENT
          return pdf_viewer_for(binary)
        when Binary::MediaCategory::IMAGE
          return image_viewer_for(item)
        when Binary::MediaCategory::TEXT
          return text_viewer_for(binary)
        when Binary::MediaCategory::THREE_D
          return three_d_viewer_for(item)
        when Binary::MediaCategory::VIDEO
          return video_player_for(binary)
      end
    end
    nil
  end

  private

  def audio_player_for(binary)
    html = StringIO.new
    if binary
      url = binary_url(binary, disposition: 'inline')
      html << "<audio id=\"dl-audio-player\" src=\"#{url}\" "\
          "type=\"#{binary.media_type}\" controls>
          <a href=\"#{url}\">Download audio</a>
      </audio>"
    end
    raw(html.string)
  end

  ##
  # @param binary [Binary]
  # @param options [Hash<Symbol,Object>]
  # @option options [Boolean] :admin
  # @return [Enumerable<Hash<Symbol,Object>>] Array of hashes with `:label`,
  #                                           `:category`, and `:value` keys.
  #
  def binary_metadata_for(binary, options = {})
    data = []
    if binary
      data << {
          label: 'Filename',
          category: 'File',
          value: File.basename(binary.object_key)
      }
      if options[:admin]
        data << {
            label: 'Object Key',
            category: 'File',
            value: binary.object_key
        }
      end
      data << {
          label: 'Media Category',
          category: 'File',
          value: binary.human_readable_media_category
      }
      data << {
          label: 'Media Type',
          category: 'File',
          value: binary.media_type
      }
      if binary.byte_size.present?
        data << {
            label: 'Size',
            category: 'File',
            value: number_to_human_size(binary.byte_size)
        }
      end
      if binary.width.present? and binary.height.present?
        data << {
            label: 'Dimensions',
            category: 'File',
            value: "#{binary.width}&times;#{binary.height}"
        }
      end
      if binary.duration.present?
        data << {
            label: 'Duration',
            category: 'File',
            value: distance_of_time_in_words(binary.duration)
        }
      end
      if binary.cfs_file_uuid.present?
        data << {
            label: 'Medusa CFS File',
            category: 'File',
            value: link_to(binary.cfs_file_uuid, binary.medusa_url,
                           target: '_blank')
        }
      end
      data << {
          label: 'DLS ID',
          category: 'File',
          value: link_to(binary.id, binary_url(binary))
      }
      begin
        binary.metadata.each do |field|
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
    data
  end

  ##
  # @param object [Item] Compound object.
  # @param selected_item [Item]
  # @return [String]
  #
  def compound_viewer_for(object, selected_item = nil)
    canvas_index = 0
    if selected_item
      # If the selected item is at the top level within a collection, object
      # may be nil, in which case the compound viewer won't work.
      return image_viewer_for(selected_item) unless object

      # If the object contains more than this many items, disable the gallery
      # view to allow the UI to load in a reasonable amount of time.
      items = object.finder.limit(999)
      if items.count > 800
        return image_viewer_for(selected_item)
      end
      items.each_with_index do |subitem, index|
        if subitem.repository_id == selected_item.repository_id
          canvas_index = index
          break
        end
      end
    end

    # Configuration is in /public/uvconfig_compound.json;
    # See http://universalviewer.io/examples/ for config structure.
    # UV seems to want its height to be defined in a style attribute.
    html = StringIO.new
    html << "<div id=\"dl-compound-viewer\" class=\"uv\" "\
      "data-locale=\"en-GB:English (GB)\" "\
      "data-config=\"#{asset_path('uvconfig_compound.json', skip_pipeline: true)}\" "\
      "data-uri=\"#{item_iiif_manifest_url(object)}\" "\
      "data-sequenceindex=\"0\" data-canvasindex=\"#{canvas_index}\" "\
      "data-rotation=\"0\" style=\"height:#{VIEWER_HEIGHT}; background-color:#000;\"></div>"
    html << javascript_include_tag('/universalviewer/lib/embed.js', id: 'embedUV')
    raw(html.string)
  end

  ##
  # @param item [Item]
  # @return [String, nil] Mailto string for injection into an anchor href, or
  #                       nil if the item's collection's repository does not
  #                       have a contact email.
  #
  def curator_mailto(item)
    mailto = nil
    email = item.collection&.medusa_repository&.email
    if email.present?
      # https://bugs.library.illinois.edu/browse/DLD-89
      website_name = Option::string(Option::Keys::WEBSITE_NAME)
      subject = sprintf('%s: %s', website_name, item.title)
      body = sprintf("This email was sent to you from the %s by a patron "\
                     "wishing to contact the curator of %s for more information.",
                     website_name, item_url(item))
      body += "%0D%0D(Enter your comment here.)%0D"
      mailto = "mailto:#{email}?subject=#{subject}&body=#{body}"
    end
    mailto
  end

  ##
  # @param count [Integer] Total number of items in the result set
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  # @param owning_entity [Item]
  # @param item_variant [Item::Variants, Symbol, nil] One of the Item::Variants
  #                     constants, or :agent_item, or nil.
  #
  def do_paginate(count, per_page, current_page,
                  max_links = ApplicationHelper::MAX_PAGINATION_LINKS,
                  owning_entity = nil, item_variant = nil)
    return '' if count <= per_page
    num_pages = (count / per_page.to_f).ceil
    first_page = [1, current_page - (max_links / 2.0).floor].max
    last_page = [first_page + max_links - 1, num_pages].min
    first_page = last_page - max_links + 1 if
        last_page - first_page < max_links and num_pages > max_links
    prev_page = [1, current_page - 1].max
    next_page = [last_page, current_page + 1].min
    prev_start = (prev_page - 1) * per_page
    next_start = (next_page - 1) * per_page
    last_start = (num_pages - 1) * per_page
    allowed_params = params.permit(ItemsController::PERMITTED_PARAMS +
                                       Admin::ItemsController::PERMITTED_PARAMS).except(:start)

    case item_variant
      when :agent_item
        first_link = link_to(agent_items_path(owning_entity, allowed_params),
                             remote: true, class: 'page-link', 'aria-label': 'First') do
          raw('<span aria-hidden="true">First</span>')
        end
        prev_link = link_to(agent_items_path(owning_entity,
                                             allowed_params.merge(start: prev_start)),
                            remote: true, class: 'page-link','aria-label': 'Previous') do
          raw('<span aria-hidden="true">&laquo;</span>')
        end
        next_link = link_to(agent_items_path(owning_entity,
                                             allowed_params.merge(start: next_start)),
                            remote: true, class: 'page-link', 'aria-label': 'Next') do
          raw('<span aria-hidden="true">&raquo;</span>')
        end
        last_link = link_to(agent_items_path(owning_entity,
                                             allowed_params.merge(start: last_start)),
                            remote: true, class: 'page-link', 'aria-label': 'Last') do
          raw('<span aria-hidden="true">Last</span>')
        end
      else
        first_link = link_to(allowed_params.except(:start),
                             remote: true, class: 'page-link', 'aria-label': 'First') do
          raw('<span aria-hidden="true">First</span>')
        end
        prev_link = link_to(allowed_params.merge(start: prev_start),
                            remote: true, class: 'page-link', 'aria-label': 'Previous') do
          raw('<span aria-hidden="true">&laquo;</span>')
        end
        next_link = link_to(allowed_params.merge(start: next_start),
                            remote: true, class: 'page-link', 'aria-label': 'Next') do
          raw('<span aria-hidden="true">&raquo;</span>')
        end
        last_link = link_to(allowed_params.merge(start: last_start),
                            remote: true, class: 'page-link', 'aria-label': 'Last') do
          raw('<span aria-hidden="true">Last</span>')
        end
    end

    # http://getbootstrap.com/components/#pagination
    html = StringIO.new
    html << '<nav>'
    html <<   '<ul class="pagination">'
    html <<     "<li class=\"page-item #{current_page == first_page ? 'disabled' : ''}\">#{first_link}</li>"
    html <<     "<li class=\"page-item #{current_page == prev_page ? 'disabled' : ''}\">#{prev_link}</li>"
    (first_page..last_page).each do |page|
      start = (page - 1) * per_page
      case item_variant
        when :agent_item
          path = (start == 0) ? agent_items_path(owning_entity, allowed_params) :
              agent_items_path(owning_entity, allowed_params.merge(start: start))
          page_link = link_to(path, class: 'page-link', remote: true) do
            raw("#{page} #{(page == current_page) ?
                '<span class="sr-only">(current)</span>' : ''}")
          end
        else
          page_link = link_to((start == 0) ? allowed_params :
                                  allowed_params.merge(start: start), class: 'page-link', remote: true) do
            raw("#{page} #{(page == current_page) ?
                '<span class="sr-only">(current)</span>' : ''}")
          end
      end
      html <<     "<li class=\"page-item #{page == current_page ? 'active' : ''}\">"
      html <<       page_link
      html <<     '</li>'
    end
    html <<     "<li class=\"page-item #{current_page == next_page ? 'disabled' : ''}\">#{next_link}</li>"
    html <<     "<li class=\"page-item #{current_page == last_page ? 'disabled' : ''}\">#{last_link}</li>"
    html <<   '</ul>'
    html << '</nav>'
    raw(html.string)
  end

  def free_form_viewer_for(item)
    binary = item.effective_viewer_binary
    case binary&.media_category
      when Binary::MediaCategory::AUDIO
        return audio_player_for(binary)
      when Binary::MediaCategory::DOCUMENT
        return pdf_viewer_for(binary)
      when Binary::MediaCategory::IMAGE
        return image_viewer_for(item)
      when Binary::MediaCategory::TEXT
        return text_viewer_for(binary)
      when Binary::MediaCategory::THREE_D
        return three_d_viewer_for(item)
      when Binary::MediaCategory::VIDEO
        return video_player_for(binary)
      else
        return viewer_unavailable_message
    end
  end

  def image_viewer_for(item)
    html = StringIO.new
    binary = item.effective_image_binary
    if binary
      # Configuration is in /public/uvconfig_single.json;
      # See http://universalviewer.io/examples/ for config structure.
      # N.B. 1: UV 2.x doesn't work in IE 9, so render an <img> instead.
      # N.B. 2: UV wants its height to be defined in a style attribute.
      html << sprintf('<!--[if (lte IE 9)]>%s<![endif]-->
          <!--[if gt IE 9 | !IE ]><!-->
          <div id="dl-image-viewer" class="uv"
          data-locale="en-GB:English (GB)"
          data-config="%s"
          data-uri="%s"
          data-sequenceindex="0" data-canvasindex="0"
          data-rotation="0" style="margin: 0 auto; width:%s; height:%s; background-color:#000;"></div>
          %s
          <![endif]-->',
                      thumbnail_tag(binary, size: 800),
                      asset_path('uvconfig_single.json', skip_pipeline: true),
                      item_iiif_manifest_url(item),
                      VIEWER_WIDTH,
                      VIEWER_HEIGHT,
                      javascript_include_tag('/universalviewer/lib/embed.js', id: 'embedUV'))
    else
      html << viewer_unavailable_message
    end
    raw(html.string)
  end

  ##
  # * If the element has a string value but no URI, or a URI not corresponding
  #   to an agent URI:
  #     * If the string value contains a URI, the string value is returned with
  #       URIs auto-linked.
  #     * If the element is searchable, the string value is returned with a
  #       link to a search for that value.
  # * If the element has a string value and a URI corresponding to an agent
  #   URI, the string value is returned linking to the corresponding show-agent
  #   page.
  # * If the element has a URI corresponding to an agent URI but no string
  #   value, the agent name is returned linking to the corresponding show-agent
  #   page.
  #
  # @param element [EntityElement]
  # @param searchable [Boolean] Whether the element is marked as searchable in
  #                             a metadata profile.
  # @return [String] HTML string.
  #
  def metadata_value_for_element(element, searchable)
    label = element.value.present? ? element.value : ''
    if element.agent
      label = label.gsub('<', '&lt;').gsub('>', '&gt;')
      label = label.present? ? label : element.agent.name
      value = link_to(label, element.agent)
    else
      label = label.gsub('<', '&lt; ').gsub('>', ' &gt;')
      value = auto_link(label, html: { target: '_blank' })
                  .gsub('&lt; ', '&lt;').gsub(' &gt;', '&gt;')
      if searchable
        # fuzzy match
        #query = label.gsub(/[^\p{L}\p{N} ]/, ' ') # allow only unicode letters, unicode numbers, and spaces
        #            .gsub(/[ ]+/, ' ')            # replace repeating spaces with a single space
        #value = label + '<br>' + link_to('See all items with this value',
        #                                 search_url(q: query, field: element.indexed_keyword_field))
        # exact match
        value = label + '&nbsp;&nbsp;' + link_to(items_path(q: label, field: element.indexed_field),
                                                 title: 'Search for all items with this element value',
                                                 class: 'btn btn-outline-secondary btn-sm') do
          raw('<i class="fa fa-search"></i>')
        end
      end
    end
    value
  end

  def pdf_viewer_for(binary)
    html = StringIO.new
    if binary
      binary_url = binary_url(binary)
      viewer_url = asset_path('/pdfjs/web/viewer.html?file=' + binary_url)
      html << '<div id="dl-pdf-viewer">'
      html <<   "<iframe src=\"#{viewer_url}\" height=\"100%\" width=\"100%\"></iframe>"
      html <<   '<div style="text-align: center">'
      html <<     link_to(viewer_url, target: '_blank', class: 'btn btn-outline-light btn-sm') do
        content_tag(:span, '', class: 'fa fa-file-pdf') + ' Open PDF in New Window'
      end
      html <<   '</div>'
      html << '</div>'
    end
    raw(html.string)
  end

  ##
  # @param binary [Binary]
  # @return [String] HTML <pre> element
  #
  def text_viewer_for(binary)
    html = StringIO.new
    if binary
      begin
        str = binary.data.string
        if str.valid_encoding?
          html << '<pre>'
          html <<   str
          html << '</pre>'
        end
      rescue Errno::ENOENT # File not found
      end
    end
    raw(html.string)
  end

  ##
  # Initializes a ThreeJSViewer. To display it, call
  # Application.view.threeDViewer.start() via JavaScript.
  #
  # ThreeJSViewer is not DLS-specific and is maintained in a separate project
  # in order to keep it decoupled and cleaner. The built minified script is
  # copied to /public.
  #
  # @see https://github.com/medusa-project/threejs-viewer
  #
  # @param item [Item]
  # @return [String] HTML string
  #
  def three_d_viewer_for(item)
    html = StringIO.new
    three_d_binaries = item.binaries.
        select{ |b| b.media_category == Binary::MediaCategory::THREE_D }
    obj_binary = three_d_binaries.
        select{ |b| b.filename&.downcase.end_with?('.obj') }.first
    if obj_binary
      mtl_binary = three_d_binaries.
          select{ |b| b.filename&.downcase.end_with?('.mtl') }.first
      # All items with OBJ models should also have one of these.
      if mtl_binary
        viewer_url = asset_path('/threejs-viewer/3dviewer.min.js')
        model_path = File.dirname(item_binary_path(item, obj_binary))

        # Initialize the viewer but don't display it yet. It will be displayed
        # via JS the first time its container div is shown.
        html << "<div id=\"dl-3d-viewer\" class=\"dl-viewer\"></div>
        <script src=\"#{viewer_url}\"></script>
        <script>
            $(document).ready(function() {
                Application.view.threeDViewer = new ThreeJSViewer({
                    'containerId': 'dl-3d-viewer',
                    'modelPath': '#{model_path}/',
                    'objFile': '#{obj_binary.filename}',
                    'mtlFile': '#{mtl_binary.filename}',
                    'ambientLightIntensity': 2.0
                });
            });
        </script>"
      end
    end
    raw(html.string)
  end

  ##
  # @param binary [Binary]
  # @return [String] HTML video element.
  #
  def video_player_for(binary)
    tag = "<video controls id=\"dl-video-player\">
      <source src=\"#{binary_url(binary)}\"
              type=\"#{binary.media_type}\">
        Your browser does not support the video tag.
    </video>"
    raw(tag)
  end

  ##
  # @return [String] Bootstrap alert div.
  #
  def viewer_unavailable_message
    raw('<div class="alert alert-info">No previewer is available for this file type.</div>')
  end

  ##
  # @param binary [Binary]
  #
  def download_label_for_binary(binary)
    dimensions = nil
    size = binary.byte_size
    size = "(#{number_to_human_size(size)})" if size
    raw("#{binary.human_readable_name} #{dimensions} #{size}")
  end

  def tech_metadata_for(item)
    data = {}
    data['Ingested'] = local_time_ago(item.created_at)
    data['Last Modified'] = local_time_ago(item.updated_at)
    data
  end

end
