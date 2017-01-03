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
      html += '<ul class="nav nav-tabs" role="tablist">'
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
  # @return [Boolean]
  #
  def client_supports_zip_download?
    # Uses the `browser` gem.
    !browser.device.console? and !browser.device.mobile? and
        !browser.device.tablet? and !browser.device.tv?
  end

  ##
  # @param items [Relation]
  # @param options [Hash] Options hash
  # @option options [Boolean] :show_collection_facet
  # @option options [MetadataProfile] :metadata_profile
  #
  def facets_as_panels(items, options = {})
    return nil unless items.facet_fields # nothing to do

    # get the list of facets to display from the appropriate metadata profile
    collection_element = MetadataProfileElement.new(name: 'collection',
                                                    facetable: true)
    profile_facetable_elements = [collection_element] +
        options[:metadata_profile].elements.where(facetable: true).
            order(:index)

    num_facets = 0
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
          num_facets += 1
          html += item_facet_panel('Collection', result_facet.terms, true)
        end
      else
        num_facets += 1
        html += item_facet_panel(element.label, result_facet.terms, false)
      end
    end
    # There is no point in having only one facet.
    num_facets > 1 ? raw(html) : ''
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
          '<div class="pt-label" title="' + child.title + '">' +
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
  # @param item [Item]
  # @return [Boolean]
  #
  def has_viewer?(item)
    # This logic needs to be kept in sync with viewer_for().
    if item.embed_tag.present? or item.is_pdf? or item.is_image? or
        item.is_audio? or item.is_video?
      return true
    elsif item.is_text?
      bs = item.access_master_bytestream || item.preservation_master_bytestream
      return bs.exists?
    end
    false
  end

  ##
  # @param bs [Bytestream]
  # @return [String, nil] Base IIIF URL or nil if the bytestream is not an
  #                       image
  #
  def iiif_bytestream_url(bs)
    if bs and (bs.is_image? or bs.is_pdf?)
      id = bs.repository_relative_pathname.reverse.chomp('/').reverse
      return Configuration.instance.iiif_url + '/' + CGI.escape(id)
    end
    nil
  end

  ##
  # @param item [Item]
  # @param size [Integer]
  # @param shape [Symbol] :default or :square
  # @return [String, nil] Image URL or nil if the item is not an image
  #
  def iiif_image_url(item, size, shape = :default)
    url = nil
    if item.is_image? or item.is_pdf?
      bs = item.access_master_bytestream || item.preservation_master_bytestream
      if bs.repository_relative_pathname and iiif_safe?(bs)
        shape = (shape == :square) ? 'square' : 'full'
        url = sprintf('%s/%s/!%d,%d/0/default.jpg',
                      item.iiif_url, shape, size, size)
      end
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
  # @param items [Enumerable<Items>]
  # @return [String]
  #
  def items_as_flex(items)
    # needs to be kept in sync with the width defined in agents.js
    thumb_width = 300
    html = ''
    items.each do |item|
      html += '<div class="pt-object">'
      html +=    link_to(item) do
        raw('<div class="pt-thumbnail">' +
                thumbnail_tag(item.effective_representative_item, thumb_width) +
            '</div>')
      end
      html += '  <h4 class="pt-title">'
      html +=      link_to(item.title, item)
      html +=      remove_from_favorites_button(item)
      html +=      add_to_favorites_button(item)
      html += '  </h4>'
      html += '</div>'
    end
    raw(html)
  end

  ##
  # @param entities [Relation<SolrQuerying>]
  # @param start [integer]
  # @param options [Hash] with available keys:
  # :link_to_admin (boolean), :show_remove_from_favorites_buttons (boolean),
  # :show_add_to_favorites_buttons (boolean),
  # :show_collections (boolean),
  # :thumbnail_size (integer)
  #
  def items_as_list(entities, start, options = {}) # TODO: rename to entities_as_list(), move to ApplicationHelper, and replace CollectionsHelper.collections_as_list()
    html = "<ol start=\"#{start + 1}\">"
    entities.each do |entity|
      if options[:link_to_admin] and entity.kind_of?(Item)
        link_target = admin_collection_item_path(entity.collection, entity)
      else
        link_target = polymorphic_path(entity)
      end
      html += '<li>'\
        '<div>'
      html += link_to(link_target, class: 'pt-thumbnail-link') do
        size = options[:thumbnail_size] ?
            options[:thumbnail_size] : DEFAULT_THUMBNAIL_SIZE
        raw('<div class="pt-thumbnail">' +
          thumbnail_tag(entity.effective_representative_item, size, :square) +
        '</div>')
      end
      html += '<span class="pt-label">'
      html += link_to(entity.title, link_target)

      # info line
      info_parts = []
      info_parts << "#{icon_for(entity)}#{type_of(entity)}"

      if entity.kind_of?(Item)
        num_pages = entity.pages.count
        if num_pages > 0
          info_parts << "#{num_pages} pages"
        else
          num_files = entity.files.count
          if num_files > 0
            info_parts << "#{num_files} files"
          else
            num_children = entity.items.count
            if num_children > 0
              info_parts << "#{num_children} sub-items"
            end
          end
        end

        date = entity.date
        if date
          info_parts << date.year
        end

        if options[:show_collections] and entity.collection
          info_parts << link_to(entity.collection.title,
                                collection_path(entity.collection))
        end
      end

      html += "<br><span class=\"pt-info-line\">#{info_parts.join(' | ')}</span>"

      if entity.kind_of?(Item)
        # remove-from-favorites button
        if options[:show_remove_from_favorites_buttons]
          html += remove_from_favorites_button(entity)
        end
        # add-to-favorites button
        if options[:show_add_to_favorites_buttons]
          html += add_to_favorites_button(entity)
        end
      end

      html += '</span>'
      html += '<br>'
      html += '<span class="pt-description">'
      html += truncate(entity.description.to_s, length: 380)
      html += '</span>'
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
      elements = item.elements.
          select{ |e| e.name == e_def.name and (e.value.present? or e.uri.present?) }
      next if elements.empty?
      html += "<dt>#{e_def.label}</dt>"
      html += '<dd>'
      if elements.length == 1
        html += metadata_value_for_element(elements.first)
      else
        html += '<ul>'
        elements.each do |element|
          html += "<li>#{metadata_value_for_element(element)}</li>"
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
      elements = item.elements.
          select{ |e| e.name == e_def.name and (e.value.present? or e.uri.present?) }
      next if elements.empty?
      html += '<tr>'
      html += "<td>#{e_def.label}</td>"
      html += '<td>'
      if elements.length == 1
        html += metadata_value_for_element(elements.first)
      else
        html += '<ul>'
        elements.each do |element|
          html += "<li>#{raw(metadata_value_for_element(element))}</li>"
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
    html = "<h2><a role=\"button\" data-toggle=\"collapse\"
      href=\"#pt-metadata\" aria-expanded=\"true\" aria-controls=\"pt-metadata\">
      Descriptive Info</a></h2>
        <div id=\"pt-metadata\" class=\"collapse in\">
          <div class=\"visible-xs\">
            #{metadata_as_list(item)}
          </div>
          <div class=\"hidden-xs\">
            #{metadata_as_table(item)}
          </div>
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
  # Returns item pagination for agent view.
  #
  # @param agent [Agent]
  # @param count [Integer]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate_agent_items(agent, count, per_page, current_page, max_links = 9)
    do_paginate(count, per_page, current_page, true, max_links, agent,
                :agent_item)
  end

  ##
  # Returns pagination for files in show-item view.
  #
  # @param count [Integer]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate_files(parent_item, count, per_page, current_page, max_links = 9)
    do_paginate(count, per_page, current_page, true, max_links,
                parent_item, Item::Variants::FILE)
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
    do_paginate(count, per_page, current_page, true, max_links)
  end

  ##
  # Returns pagination for pages in show-item view.
  #
  # @param count [Integer]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate_pages(parent_item, count, per_page, current_page, max_links = 9)
    do_paginate(count, per_page, current_page, true, max_links, parent_item,
                Item::Variants::PAGE)
  end

  ##
  # Returns what the user is searching for.
  #
  # @param q [String] From params
  # @param fq [Array<String>] From params
  # @param profile [MetadataProfile]
  # @return [String]
  #
  def query_summary(q, fq, profile)
    query = ''
    if fq&.any? or q.present?
      query = '<ul class="pt-query-summary">'
      if q.present?
        query += "<li>Filter: <span class=\"pt-query-summary-value\">\"#{h(q)}\"</span></li>"
      end
      fq&.each do |fq_|
        parts = fq_.split(':')
        if parts.length == 2
          name = parts[0].chomp(EntityElement.solr_facet_suffix).
              chomp(EntityElement.solr_suffix)
          label = profile.elements.select{ |e| e.name == name }.first.label
          value = parts[1].chomp('"').reverse.chomp('"').reverse

          query += "<li>#{label}: <span class=\"pt-query-summary-value\">#{value}</span></li>"
        end
      end
      query += '</ul>'
    end
    raw(query)
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
          'contentUrl': iiif_image_url(item, 1024)
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
      struct[:thumbnailUrl] = iiif_image_url(item, ItemsHelper::DEFAULT_THUMBNAIL_SIZE)
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
    raw("Showing #{start + 1}&ndash;#{last} of #{number_with_delimiter(total)} items")
  end

  ##
  # @param entity [Item, Agent]
  # @return [String] HTML string
  #
  def share_button(entity)
    title = entity.respond_to?(:title) ? entity.title : entity.name
    description = entity.description
    url = entity.kind_of?(Item) ? item_url(entity) : agent_url(entity)

    html = '<div class="btn-group">
      <button type="button" class="btn btn-default dropdown-toggle"
            data-toggle="dropdown" aria-expanded="false">
        <i class="fa fa-share-alt"></i> Share <span class="caret"></span>
      </button>'
    html += '<ul class="dropdown-menu" role="menu">'
    # cite
    if entity.kind_of?(Item)
      html += '<li>'
      html += link_to('#', onclick: 'return false;', data: { toggle: 'modal',
                                                             target: '#pt-cite-modal' }) do
        raw('<i class="fa fa-pencil"></i> Cite')
      end
      html += '</li>'
      html += '<li class="divider"></li>'
    end
    # email
    html += '<li>'
    html += link_to("mailto:?subject=#{CGI::escape(title)}&body=#{CGI::escape(url)}") do
      raw('<i class="fa fa-envelope"></i> Email')
    end
    html += '</li>'
    html += '<li class="divider"></li>'
    # facebook
    html += '<li>'
    html += link_to("https://www.facebook.com/sharer/sharer.php?u=#{CGI::escape(url)}") do
      raw('<i class="fa fa-facebook-square"></i> Facebook')
    end
    html += '</li>'
    # linkedin
    html += '<li>'
    html += link_to("http://www.linkedin.com/shareArticle?mini=true&url=#{CGI::escape(url)}&title=#{CGI::escape(title)}&summary=#{description}") do
      raw('<i class="fa fa-linkedin-square"></i> LinkedIn')
    end
    html += '</li>'
    # twitter
    html += '<li>'
    html += link_to("http://twitter.com/home?status=#{CGI::escape(title)}%20#{CGI::escape(url)}") do
      raw('<i class="fa fa-twitter-square"></i> Twitter')
    end
    html += '</li>'
    # google+
    html += '<li>'
    html += link_to("https://plus.google.com/share?url=#{CGI::escape(title)}%20#{CGI::escape(url)}") do
      raw('<i class="fa fa-google-plus-square"></i> Google+')
    end
    html += '</li>'
    # pinterest
    url = "http://pinterest.com/pin/create/button/?url=#{CGI::escape(url)}&description=#{CGI::escape(title)}"
    if entity.kind_of?(Item)
      iiif_url = iiif_image_url(entity, 512)
      if iiif_url
        url += "&media=#{CGI::escape(iiif_url)}"
      end
    end
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
  def thumbnail_tag(entity, size = DEFAULT_THUMBNAIL_SIZE, shape = :default)
    url = nil
    if entity.kind_of?(Bytestream)
      url = bytestream_image_url(entity, size, shape)
    elsif entity.kind_of?(Collection)
      bs = entity.representative_image_bytestream
      if bs
        url = bytestream_image_url(bs, size, shape)
      end
    elsif entity.kind_of?(Item)
      url = iiif_image_url(entity, size, shape)
    end

    html = ''
    if url
      # No alt because it may appear in a huge font size if the image is 404.
      html += image_tag(url, class: 'pt-thumbnail', alt: '')
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
  def thumbnail_url(entity, size = DEFAULT_THUMBNAIL_SIZE, shape = :default)
    url = nil
    if entity.kind_of?(Bytestream)
      url = bytestream_image_url(entity, size, shape)
    elsif entity.kind_of?(Item)
      url = iiif_image_url(entity, size, shape)
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
    # This logic needs to be kept in sync with has_viewer?().
    if item.embed_tag.present?
      # Replace hard-coded width/height attribute values.
      frag = Nokogiri::HTML::DocumentFragment.parse(item.embed_tag)
      frag.xpath('.//@width').remove
      frag.xpath('.//@height').remove
      # These must be kept in sync with the viewer CSS dimensions.
      frag.xpath('.//*').first['width'] = '100%'
      frag.xpath('.//*').first['height'] = '400'
      return raw(frag.to_html.strip)
    elsif item.is_compound?
      return compound_viewer_for(item)
    elsif item.is_pdf?
      return pdf_viewer_for(item)
    elsif item.is_image?
      return image_viewer_for(item)
    elsif item.is_audio?
      return audio_player_for(item)
    elsif item.is_text?
      bs = item.access_master_bytestream || item.preservation_master_bytestream
      pathname = bs.absolute_local_pathname
      begin
        return raw("<pre>#{File.read(pathname)}</pre>")
      rescue Errno::ENOENT # File not found
        return ''
      end
    elsif item.is_video?
      return video_player_for(item)
    end
    nil
  end

  private

  ##
  # @param item [Item]
  # @return [String] HTML <button> element
  #
  def add_to_favorites_button(item)
    html = '<button class="btn btn-default btn-xs ' +
        'pt-add-to-favorites" data-item-id="' + item.repository_id + '">'
    html += '  <i class="fa fa-heart-o"></i>'
    html += '</button>'
    raw(html)
  end

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
      if options[:admin]
        data << {
            label: 'Pathname',
            category: 'File',
            value: bytestream.absolute_local_pathname
        }
      else
        data << {
            label: 'Filename',
            category: 'File',
            value: File.basename(bytestream.absolute_local_pathname)
        }
      end
      if bytestream.cfs_file_uuid.present?
        data << {
            label: 'Medusa CFS File',
            category: 'File',
            value: link_to(bytestream.cfs_file_uuid, bytestream.medusa_url,
                           target: '_blank')
        }
      end
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
    data
  end

  ##
  # @param item [Item]
  # @return [String]
  #
  def compound_viewer_for(item)
    html = ''
    if item.is_compound?
      # Configuration is in /public/uvconfig_compound.json;
      # See http://universalviewer.io/examples/ for config structure.
      # UV seems to want its height to be defined in a style attribute.
      html += "<div id=\"pt-compound-viewer\" class=\"uv\" "\
        "data-locale=\"en-GB:English (GB)\" "\
        "data-config=\"#{asset_path('uvconfig_compound.json')}\" "\
        "data-uri=\"#{item_iiif_manifest_url(item)}\" "\
        "data-sequenceindex=\"0\" data-canvasindex=\"0\" "\
        "data-rotation=\"0\" style=\"height:600px; background-color:#000;\"></div>"
      html += javascript_include_tag('/universalviewer/lib/embed.js', id: 'embedUV')
    end
    raw(html)
  end

  ##
  # @param item [Item]
  # @return [String, nil] Mailto string for injection into an anchor href, or
  #                       nil if the item's collection's repository does not
  #                       have a contact email.
  #
  def curator_mailto(item)
    mailto = nil
    email = item.collection.medusa_repository&.email
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
  # @param count [Integer] Total number of items in the result set
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param remote [Boolean]
  # @param max_links [Integer] (ideally odd)
  # @param owning_entity [Item]
  # @param item_variant [Item::Variants, Symbol, nil] One of the Item::Variants
  #                     constants, or :agent_item, or nil.
  #
  def do_paginate(count, per_page, current_page, remote = false,
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

    # TODO: DRY this
    case item_variant
      when Item::Variants::FILE
        first_link = link_to(item_files_path(owning_entity,
                                             params.except(:start).symbolize_keys),
                             remote: remote, 'aria-label': 'First') do
          raw('<span aria-hidden="true">First</span>')
        end
        prev_link = link_to(item_files_path(owning_entity,
                                            params.merge(start: prev_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Previous') do
          raw('<span aria-hidden="true">&laquo;</span>')
        end
        next_link = link_to(item_files_path(owning_entity,
                                            params.merge(start: next_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Next') do
          raw('<span aria-hidden="true">&raquo;</span>')
        end
        last_link = link_to(item_files_path(owning_entity,
                                            params.merge(start: last_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Last') do
          raw('<span aria-hidden="true">Last</span>')
        end
      when Item::Variants::PAGE
        first_link = link_to(item_pages_path(owning_entity,
                                             params.except(:start).symbolize_keys),
                             remote: remote, 'aria-label': 'First') do
          raw('<span aria-hidden="true">First</span>')
        end
        prev_link = link_to(item_pages_path(owning_entity,
                                            params.merge(start: prev_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Previous') do
          raw('<span aria-hidden="true">&laquo;</span>')
        end
        next_link = link_to(item_pages_path(owning_entity,
                                            params.merge(start: next_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Next') do
          raw('<span aria-hidden="true">&raquo;</span>')
        end
        last_link = link_to(item_pages_path(owning_entity,
                                            params.merge(start: last_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Last') do
          raw('<span aria-hidden="true">Last</span>')
        end
      when :agent_item
        first_link = link_to(agent_items_path(owning_entity,
                                             params.except(:start).symbolize_keys),
                             remote: remote, 'aria-label': 'First') do
          raw('<span aria-hidden="true">First</span>')
        end
        prev_link = link_to(agent_items_path(owning_entity,
                                            params.merge(start: prev_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Previous') do
          raw('<span aria-hidden="true">&laquo;</span>')
        end
        next_link = link_to(agent_items_path(owning_entity,
                                            params.merge(start: next_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Next') do
          raw('<span aria-hidden="true">&raquo;</span>')
        end
        last_link = link_to(agent_items_path(owning_entity,
                                            params.merge(start: last_start).symbolize_keys),
                            remote: remote, 'aria-label': 'Last') do
          raw('<span aria-hidden="true">Last</span>')
        end
      else
        first_link = link_to(params.except(:start),
                             remote: remote, 'aria-label': 'First') do
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
      case item_variant
        when Item::Variants::FILE
          path = (start == 0) ? item_files_path(owning_entity, params.except(:start).symbolize_keys) :
              item_files_path(owning_entity, params.merge(start: start).symbolize_keys)
          page_link = link_to(path, remote: remote) do
            raw("#{page} #{(page == current_page) ?
                '<span class="sr-only">(current)</span>' : ''}")
          end
        when Item::Variants::PAGE
          path = (start == 0) ? item_pages_path(owning_entity, params.except(:start).symbolize_keys) :
              item_pages_path(owning_entity, params.merge(start: start).symbolize_keys)
          page_link = link_to(path, remote: remote) do
            raw("#{page} #{(page == current_page) ?
                '<span class="sr-only">(current)</span>' : ''}")
          end
        when :agent_item
          path = (start == 0) ? agent_items_path(owning_entity, params.except(:start).symbolize_keys) :
              agent_items_path(owning_entity, params.merge(start: start).symbolize_keys)
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
        return false if bs.byte_size > max_size
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
      # Configuration is in /public/uvconfig_single.json;
      # See http://universalviewer.io/examples/ for config structure.
      # UV seems to want its height to be defined in a style attribute.
      html += "<div id=\"pt-image-viewer\" class=\"uv\" "\
      "data-locale=\"en-GB:English (GB)\" "\
      "data-config=\"#{asset_path('uvconfig_single.json')}\" "\
      "data-uri=\"#{item_iiif_manifest_url(item)}\" "\
      "data-sequenceindex=\"0\" data-canvasindex=\"0\" "\
      "data-rotation=\"0\" style=\"margin: 0 auto; width: 96%; height:600px; background-color:#000;\"></div>"
      html += javascript_include_tag('/universalviewer/lib/embed.js', id: 'embedUV')
    end
    raw(html)
  end

  def item_facet_panel(title, terms, for_collections = false)
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

  ##
  # If the element has a string value but no URI, or a URI not corresponding to
  # an agent URI, returns the string value with URIs auto-linked.
  #
  # If the element has a string value and a URI corresponding to an agent URI,
  # returns the string value linking to the corresponding show-agent page.
  #
  # If the element has a URI corresponding to an agent URI but no string value,
  # returns the agent name linking to the corresponding show-agent page.
  #
  # @param element [EntityElement]
  # @return [String] HTML string
  #
  def metadata_value_for_element(element)
    if element.agent
      label = element.value.present? ? element.value : element.agent.name
      value = link_to(label, element.agent)
    else
      value = auto_link(element.value)
    end
    value
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
      html += "<iframe src=\"#{viewer_url}\" height=\"100%\" width=\"100%\"></iframe>"

      html += link_to(viewer_url, target: '_blank',
                      class: 'btn btn-default') do
        content_tag(:span, '', class: 'fa fa-file-pdf-o') + ' Open in New Window'
      end
    end
    html += '</div>'
    raw(html)
  end

  ##
  # @param item [Item]
  # @return [String] HTML <button> element
  #
  def remove_from_favorites_button(item)
    html = '<button class="btn btn-xs btn-danger ' +
        'pt-remove-from-favorites" data-item-id="' + item.repository_id + '">'
    html += '  <i class="fa fa-heart"></i> Remove'
    html += '</button>'
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
