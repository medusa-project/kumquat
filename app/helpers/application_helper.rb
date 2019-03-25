module ApplicationHelper

  CARD_IMAGE_SIZE = 512
  MAX_PAGINATION_LINKS = 9

  ##
  # Adds a full-window AJAX shade element to the DOM. This will be initially
  # hidden via CSS, and can be toggled on and off by
  # Application.AJAXShade.show() and hide().
  #
  # @return [String]
  #
  def ajax_shade
    html = '<div id="pt-ajax-shade"></div>'
    raw(html)
  end

  def bootstrap_class_for(flash_type)
    case flash_type.to_sym
      when :success
        'alert-success'
      when :error
        'alert-danger'
      when :alert
        'alert-block'
      when :notice
        'alert-info'
      else
        flash_type.to_s
    end
  end

  ##
  # Formats a boolean for display.
  #
  # @param boolean [Boolean]
  # @return [String]
  #
  def boolean(boolean)
    raw(boolean ? '<span class="text-success">&check;</span>' :
            '<span class="text-danger">&times;</span>')
  end

  ##
  # @param options [Hash]
  # @option options [Collection] :collection
  # @option options [ItemsController::BrowseContext] :context
  # @option options [String] :context_url
  # @option options [Item] :item
  # @return [String]
  #
  def breadcrumb(options = {})
    case controller_name
      when 'collections'
        case action_name
          when 'index'
            return nil # no breadcrumb in this view
          when 'show'
            return collection_view_breadcrumb(options[:collection])
        end
      when 'items'
        case action_name
          when 'tree'
            return results_breadcrumb(options[:collection], options[:context])
          when 'index'
            return results_breadcrumb(options[:collection], options[:context])
          when 'show'
            return item_view_breadcrumb(options[:item], options[:context],
                                        options[:context_url])
        end
    end
    nil
  end

  ##
  # @param entities [Enumerable<Collection>, Enumerable<Item>]
  # @return [String]
  #
  def entities_as_cards(entities)
    html = StringIO.new
    entities.each do |entity|
      bin = nil
      if Option::string(Option::Keys::SERVER_STATUS) != 'storage_offline'
        begin
          # If the entity is a Collection and the reference to the binary is
          # invalid (for example, an invalid UUID has been entered), this will
          # raise an error.
          bin = entity.effective_representative_image_binary
        rescue => e
          CustomLogger.instance.warn("entities_as_cards(): #{e} (#{entity})")
        end
      end
      if bin&.iiif_safe?
        img_url = binary_image_url(bin, region: 'square', size: CARD_IMAGE_SIZE)
      else
        case entity.class.to_s
          when 'Collection'
            img_url = image_url('fa-folder-open-o-600.png')
          else
            img_url = image_url('fa-cube-600.png')
        end
      end
      html << '<div class="pt-card">'
      html <<   '<div class="pt-card-content">'
      html <<     link_to(entity) do
        raw("<img src=\"#{img_url}\">")
      end
      html <<     '<h4 class="pt-title">'
      html <<       link_to(entity.title, entity)
      html <<     '</h4>'
      html <<   '</div>'
      html << '</div>'
    end
    raw(html.string)
  end

  ##
  # Returns an ordered list of the given entities (Items, Collections, Agents).
  #
  # @param entities [Enumerable<Representable>]
  # @param start [integer] Offset.
  # @param options [Hash] Hash with optional keys.
  # @option options [Boolean] :link_to_admin
  # @option options [Boolean] :show_collections
  # @option options [Boolean] :show_checkboxes
  # @option options [Boolean] :show_published_status
  # @return [String] HTML string.
  #
  def entities_as_list(entities, start, options = {})
    html = StringIO.new
    html << "<ol start=\"#{start + 1}\">"
    entities.each do |entity|
      if options[:link_to_admin] and entity.kind_of?(Item)
        link_target = admin_collection_item_path(entity.collection, entity)
      else
        link_target = polymorphic_path(entity)
      end
      html << '<li>'
      if options[:show_checkboxes]
        html << check_box_tag('pt-selected-items[]', entity.repository_id)
        html << '<div class="pt-checkbox-result-container">'
      else
        html << '<div class="pt-non-checkbox-result-container">'
      end
      html << link_to(link_target, class: 'pt-thumbnail-link') do
        thumb = StringIO.new
        thumb << '<div class="pt-thumbnail">'
        thumb << thumbnail_tag(entity.effective_representative_entity,
                               shape: :square)
        thumb << '</div>'
        raw(thumb.string)
      end
      html << '<span class="pt-label">'
      html << link_to(entity.title, link_target)

      # info line
      info_parts = []
      info_parts << "#{icon_for(entity)}#{type_of(entity)}"

      if entity.class.to_s == 'Item'
        num_pages = entity.pages.count
        if num_pages > 1
          page_count = "#{num_pages} pages"
          three_d_item = entity.three_d_item
          page_count += ' + 3D model' if three_d_item
          info_parts << page_count
        else
          num_files = entity.items.where(variant: Item::Variants::FILE).count
          if num_files > 0
            info_parts << "#{num_files} files"
          else
            num_children = entity.items.count
            if num_children > 0
              info_parts << "#{num_children} sub-items"
            end
          end
        end

        range = [
            entity.respond_to?(:date) ? entity.date : nil,
            entity.respond_to?(:end_date) ? entity.end_date : nil
        ]
        info_parts << range.select(&:present?).map(&:year).join('-') if range.any?

        if options[:show_collections] and entity.collection
          info_parts << link_to(entity.collection.title,
                                collection_path(entity.collection))
        end
      end

      if options[:show_published_status] and entity.respond_to?(:published)
        if entity.published
          info_parts << '<span class="label label-success"><i class="fa fa-check"></i> Published</label>'
        else
          info_parts << '<span class="label label-danger"><i class="fa fa-lock"></i> Unpublished</label>'
        end
      end

      html <<   '<br>'
      html <<   '<span class="pt-info-line">'
      html <<     info_parts.join(' | ')
      html <<   '</span>'
      html << '</span>'
      html << '<br>'
      html << '<span class="pt-description">'

      description = nil
      if entity.kind_of?(Item)
        desc_e = entity.collection.descriptive_element
        if desc_e
          description = entity.element(desc_e.name)&.value
        end
      else
        description = entity.description.to_s
      end
      if description
        html << truncate(description, length: 380)
      end

      html <<       '</span>'
      html <<     '</div>'
      html <<   '</li>'
    end
    html << '</ol>'
    raw(html.string)
  end

  ##
  # @param facets [Enumerable<Facet>]
  # @param permitted_params [ActionController::Parameters]
  # @return [String] HTML string
  #
  def facets_as_panels(facets, permitted_params)
    return nil unless facets
    html = StringIO.new
    facets.select{ |f| f.terms.any? }.each do |facet|
      html << facet_panel(facet, params.permit(permitted_params))
    end
    raw(html.string)
  end

  ##
  # @return [String]
  #
  def favicon_link_tags
    # https://uofi.app.box.com/v/Illinois-Logo/file/209399852568
    html = "<link rel=\"apple-touch-icon\" sizes=\"57x57\" href=\"#{image_url('apple-icon-57x57.png')}\">
    <link rel=\"apple-touch-icon\" sizes=\"60x60\" href=\"#{image_url('apple-icon-60x60.png')}\">
    <link rel=\"apple-touch-icon\" sizes=\"72x72\" href=\"#{image_url('apple-icon-72x72.png')}\">
    <link rel=\"apple-touch-icon\" sizes=\"76x76\" href=\"#{image_url('apple-icon-76x76.png')}\">
    <link rel=\"apple-touch-icon\" sizes=\"114x114\" href=\"#{image_url('apple-icon-114x114.png')}\">
    <link rel=\"apple-touch-icon\" sizes=\"120x120\" href=\"#{image_url('apple-icon-120x120.png')}\">
    <link rel=\"apple-touch-icon\" sizes=\"144x144\" href=\"#{image_url('apple-icon-144x144.png')}\">
    <link rel=\"apple-touch-icon\" sizes=\"152x152\" href=\"#{image_url('apple-icon-152x152.png')}\">
    <link rel=\"apple-touch-icon\" sizes=\"180x180\" href=\"#{image_url('apple-icon-180x180.png')}\">
    <link rel=\"icon\" type=\"image/png\" sizes=\"192x192\" href=\"#{image_url('android-icon-192x192.png')}\">
    <link rel=\"icon\" type=\"image/png\" sizes=\"32x32\" href=\"#{image_url('favicon-32x32.png')}\">
    <link rel=\"icon\" type=\"image/png\" sizes=\"96x96\" href=\"#{image_url('favicon-96x96.png')}\">
    <link rel=\"icon\" type=\"image/png\" sizes=\"16x16\" href=\"#{image_url('favicon-16x16.png')}\">
    <meta name=\"msapplication-TileColor\" content=\"#ffffff\">
    <meta name=\"msapplication-TileImage\" content=\"#{image_url('ms-icon-144x144.png')}\">
    <meta name=\"theme-color\" content=\"#ffffff\">"
    raw(html)
  end

  def feedback_link
    subject = 'Feedback on ' + Option::string(Option::Keys::WEBSITE_NAME)
    body = 'Page URL: ' + request.url
    url = sprintf('mailto:%s?subject=%s&body=%s',
                  Option::string(Option::Keys::ADMINISTRATOR_EMAIL),
                  subject,
                  body)
    link = link_to('Contact us', url)
    html = sprintf('The Digital Collections are a product of the University Library.
      %s for questions and to provide feedback.', link)
    raw(html)
  end

  ##
  # @return [String] Bootstrap alerts for each flash message.
  #
  def flashes
    html = StringIO.new
    flash.each do |type, message|
      html << "<div class=\"pt-flash alert alert-dismissable #{bootstrap_class_for(type)}\">"
      html <<   '<button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>'
      html <<   message
      html << '</div>'
    end
    raw(html.string)
  end

  ##
  # Returns the most appropriate icon for the given object, which may be an
  # Item, Binary, Collection, etc. If the object is unrecognized, a generic
  # icon will be returned.
  #
  # @param entity [Object]
  # @return [String] HTML <i> tag
  #
  def icon_for(entity)
    icon = 'fa-cube'
    if entity == Item
      icon = 'fa-cube'
    elsif entity.kind_of?(Item)
      viewer_binary = entity.effective_viewer_binary
      if viewer_binary&.is_audio?
        icon = 'fa-volume-up'
      elsif viewer_binary&.is_image?
        icon = 'fa-picture-o'
      elsif viewer_binary&.is_document?
        icon = 'fa-file-pdf-o'
      elsif viewer_binary&.is_text?
        icon = 'fa-file-text-o'
      elsif viewer_binary&.is_video?
        icon = 'fa-film'
      elsif entity.variant == Item::Variants::DIRECTORY
        icon = 'fa-folder-open-o'
      elsif entity.variant == Item::Variants::FILE
        icon = 'fa-file-o'
      elsif entity.items.any?
        icon = 'fa-cubes'
      end
    elsif entity.kind_of?(Binary)
      if entity.is_audio?
        icon = 'fa-volume-up'
      elsif entity.is_image?
        icon = 'fa-picture-o'
      elsif entity.is_pdf?
        icon = 'fa-file-pdf-o'
      elsif entity.is_text?
        icon = 'fa-file-text-o'
      elsif entity.is_video?
        icon = 'fa-film'
      end
    elsif entity == Collection or entity.kind_of?(Collection)
      icon = 'fa-folder-open-o'
    elsif entity == Agent or entity.kind_of?(Agent)
      icon = 'fa-user-circle'
    elsif entity == ItemSet or entity.kind_of?(ItemSet)
      icon = 'fa-circle-o'
    elsif entity == User or entity.kind_of?(User)
      icon = 'fa-user'
    end
    raw("<i title=\"#{type_of(entity)}\" class=\"fa #{icon} pt-icon\"></i>")
  end

  ##
  # Overrides Rails' implementation to use the correct scheme.
  #
  # @param image [String]
  # @param options [Hash]
  # @return [String]
  #
  def image_url(image, options = {})
    URI.join(root_url, image_path(image, options)).to_s
  end

  ##
  # Returns a deferred img tag (with data-src set instead of src) for
  # lazy-loading using JavaScript.
  #
  # @param source [String]
  # @param options [Hash]
  # @return [String]
  #
  def lazy_image_tag(source, options = {})
    image_tag(source, options).gsub(' src=', ' data-src=').
        gsub('<img ', '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=" ')
  end

  ##
  # @param search_term [String]
  # @param suggestions [Enumerable<String>]
  # @return [String] HTML string
  #
  def no_results_help(search_term, suggestions)
    html = StringIO.new
    if search_term.present?
      html << "<p class=\"alert alert-warning\">Sorry, we couldn't find "\
      "anything matching &quot;#{h(search_term)}&quot;.</p>"
      if suggestions.any?
        html << '<p>Did you mean:</p>'
        html << '<ul>'
        suggestions.each do |suggestion|
          html <<   '<li>'
          html <<     link_to(suggestion, { q: suggestion })
          html <<   '</li>'
        end
        html << '</ul>'
      end
    else
      html << '<p>No results.</p>'
    end
    raw(html.string)
  end

  ##
  # @param entities [ActiveRecord::Relation]
  # @param total_entities [Integer]
  # @param per_page [Integer]
  # @param permitted_params [ActionController::Parameters]
  # @param current_page [Integer]
  # @param remote [Boolean]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate(total_entities, per_page, current_page, permitted_params,
               remote = false, max_links = MAX_PAGINATION_LINKS)
    return '' if total_entities <= per_page
    num_pages  = (total_entities / per_page.to_f).ceil
    first_page = [1, current_page - (max_links / 2.0).floor].max
    last_page  = [first_page + max_links - 1, num_pages].min
    first_page = last_page - max_links + 1 if
        last_page - first_page < max_links and num_pages > max_links
    prev_page  = [1, current_page - 1].max
    next_page  = [last_page, current_page + 1].min
    prev_start = (prev_page - 1) * per_page
    next_start = (next_page - 1) * per_page
    last_start = (num_pages - 1) * per_page
    permitted_params = params.permit(params.permit(permitted_params))

    first_link = link_to(permitted_params.except(:start),
                         remote: remote, 'aria-label': 'First') do
      raw('<span aria-hidden="true">First</span>')
    end
    prev_link = link_to(permitted_params.merge(start: prev_start),
                        remote: remote, 'aria-label': 'Previous') do
      raw('<span aria-hidden="true">&laquo;</span>')
    end
    next_link = link_to(permitted_params.merge(start: next_start),
                        remote: remote, 'aria-label': 'Next') do
      raw('<span aria-hidden="true">&raquo;</span>')
    end
    last_link = link_to(permitted_params.merge(start: last_start),
                        remote: remote, 'aria-label': 'Last') do
      raw('<span aria-hidden="true">Last</span>')
    end

    # http://getbootstrap.com/components/#pagination
    html = StringIO.new
    html << '<nav>'
    html <<   '<ul class="pagination">'
    html <<     "<li #{current_page == first_page ? 'class="disabled"' : ''}>#{first_link}</li>"
    html <<     "<li #{current_page == prev_page ? 'class="disabled"' : ''}>#{prev_link}</li>"
    (first_page..last_page).each do |page|
      start = (page - 1) * per_page
      page_link = link_to((start == 0) ? permitted_params.except(:start) :
                              permitted_params.merge(start: start), remote: remote) do
        raw("#{page} #{(page == current_page) ?
            '<span class="sr-only">(current)</span>' : ''}")
      end
      html << "<li class=\"#{page == current_page ? 'active' : ''}\">"
      html <<   page_link
      html << '</li>'
    end
    html <<     "<li #{current_page == next_page ? 'class="disabled"' : ''}>#{next_link}</li>"
    html <<     "<li #{current_page == last_page ? 'class="disabled"' : ''}>#{last_link}</li>"
    html <<   '</ul>'
    html << '</nav>'
    raw(html.string)
  end

  ##
  # @param statement [RightsStatement, nil]
  # @param text [String, nil]
  # @return [String]
  #
  def rights_statement(statement, text)
    html = StringIO.new
    if statement or text.present?
      if statement
        image = link_to(statement.info_uri, target: '_blank') do
          image_tag(statement.image,
                    alt: "#{statement.name} (RightsStatement.org)")
        end
      else
        image = '<i class="fa fa-copyright"></i>'
      end

      title = statement ? '' : '<h4 class="media-heading">Rights Information</h4>'
      text = text.present? ? "<p>#{auto_link(text)}</p>" : ''

      html << '<div class="media pt-rights">'
      html <<   '<div class="media-left">'
      html <<     image
      html <<   '</div>'
      html <<   '<div class="media-body">'
      html <<     title
      html <<     text
      html <<   '</div>'
      html << '</div>'
    end
    raw(html.string)
  end

  ##
  # @return [String] Bootstrap alert div, or an empty string if there is no
  #                  server status message.
  #
  def server_status_message
    status = Option::string(Option::Keys::SERVER_STATUS)
    message = Option::string(Option::Keys::SERVER_STATUS_MESSAGE)
    html = ''
    if status != 'online' and message.present?
      html += "<div class=\"pt-flash alert alert-warning\">
          <i class=\"fa fa-warning\"></i> #{message}
        </div>"
    end
    raw(html)
  end

  ##
  # @param entity [Object]
  # @return [String] Text description of the entity's type
  #
  def type_of(entity)
    type = 'Item'
    if entity == Item
      type = 'Item'
    elsif entity.kind_of?(Item)
      viewer_binary = entity.effective_viewer_binary
      if viewer_binary&.is_3d?
        type = '3D'
      elsif viewer_binary&.is_audio?
        type = 'Audio'
      elsif viewer_binary&.is_image?
        type = 'Image'
      elsif viewer_binary&.is_document?
        type = 'Document'
      elsif viewer_binary&.is_text?
        type = 'Text'
      elsif viewer_binary&.is_video?
        type = 'Video'
      elsif entity.variant == Item::Variants::FILE
        type = 'File'
      elsif entity.variant == Item::Variants::DIRECTORY
        type = 'File Folder'
      elsif entity.pages.count > 1
        type = 'Multi-Page Item'
      end
    else
      type = entity.kind_of?(Class) ? entity.name : entity.class.name
    end
    type
  end

  private

  def collection_structure_breadcrumb(collection)
    html = StringIO.new
    parent = collection.parents.first
    while parent
      html << '<li>'
      html << link_to(parent.title, parent)
      html << '</li>'
      html << html.string
      parent = parent.parents.first
    end
    html << "<li class=\"active\">#{truncate(collection.title, length: 50)}</li>"
    html.string
  end

  def collection_view_breadcrumb(collection)
    html = StringIO.new
    html << '<ol class="breadcrumb">'
    html <<   '<li>'
    html <<     link_to('Home', root_path)
    html <<   '</li>'
    html <<   '<li>'
    html <<     repository_link(collection)
    html <<   '</li>'
    html <<   collection_structure_breadcrumb(collection)
    html << '</ol>'
    raw(html.string)
  end

  ##
  # @param facet [Facet]
  #
  def facet_panel(facet, permitted_params)
    panel = StringIO.new
    panel << "<div class=\"panel panel-default\" id=\"#{facet.field}\">
      <div class=\"panel-heading\">
        <h3 class=\"panel-title\">#{facet.name}</h3>
      </div>
      <div class=\"panel-body\">
        <ul>"
    facet.terms.each do |term|
      checked = (params[:fq] and params[:fq].include?(term.query)) ?
                    'checked' : nil
      checked_params = term.removed_from_params(permitted_params.deep_dup).except(:start)
      unchecked_params = term.added_to_params(permitted_params.deep_dup).except(:start)
      term_label = truncate(term.label, length: 80)

      panel << '<li class="pt-term">'
      panel <<   '<div class="checkbox">'
      panel <<     '<label>'
      panel <<       "<input type=\"checkbox\" name=\"pt-facet-term\" #{checked} "\
                         "data-query=\"#{term.query.gsub('"', '&quot;')}\" "\
                         "data-checked-href=\"#{url_for(unchecked_params)}\" "\
                         "data-unchecked-href=\"#{url_for(checked_params)}\">"
      panel <<         "<span class=\"pt-term-name\">#{term_label}</span> "
      panel <<         "<span class=\"pt-count badge\">#{term.count}</span>"
      panel <<     '</label>'
      panel <<   '</div>'
      panel << '</li>'
    end
    panel <<     '</ul>'
    panel <<   '</div>'
    panel << '</div>'
    raw(panel.string)
  end

  def item_structure_breadcrumb(item)
    html = StringIO.new
    parent = item.parent
    while parent
      html << '<li>'
      html <<   link_to(parent.title, parent)
      html << '</li>'
      html << html.string
      parent = parent.parent
    end
    html << '<li class="active">'
    html <<   truncate(item.title, length: 50)
    html << '</li>'
    html.string
  end

  def item_view_breadcrumb(item, context, context_url)
    html = StringIO.new
    case context
      when ItemsController::BrowseContext::SEARCHING
        html << '<ol class="breadcrumb">'
        html <<   "<li>#{link_to 'Home', root_path}</li>"
        html <<   "<li>#{link_to 'Search', context_url}</li>"
        html <<   item_structure_breadcrumb(item)
        html << "</ol>"
      when ItemsController::BrowseContext::BROWSING_ALL_ITEMS
        html << '<ol class="breadcrumb">'
        html <<   "<li>#{link_to 'Home', root_path}</li>"
        html <<   "<li>#{link_to 'All Items', items_path}</li>"
        html <<   item_structure_breadcrumb(item)
        html << "</ol>"
      else
        html << '<ol class="breadcrumb">'
        html <<   "<li>#{link_to 'Home', root_path}</li>"
        html <<   "<li>#{repository_link(item.collection)}</li>"
        html <<   "<li>#{link_to item.collection.title, collection_path(item.collection)}</li>"
        html <<   "<li>#{link_to 'Items', collection_items_path(item.collection)}</li>"
        html <<   item_structure_breadcrumb(item)
        html << '</ol>'
    end
    raw(html.string)
  end

  def repository_link(collection)
    fq = "#{Collection::IndexFields::REPOSITORY_TITLE}:#{collection.medusa_repository.title}"
    link_to collection.medusa_repository.title, collections_path('fq[]': fq)
  end

  def results_breadcrumb(collection, context)
    if context == ItemsController::BrowseContext::BROWSING_COLLECTION
      html = StringIO.new
      html << '<ol class="breadcrumb">'
      html <<   "<li>#{link_to('Home', root_path)}</li>"
      html <<   "<li>#{repository_link(collection)}</li>"
      html <<   "<li>#{link_to(truncate(collection.title, length: 50), collection_path(collection))}</li>"
      html <<   '<li class="active">Items</li>'
      html << '</ol>'
      raw(html.string)
    end
  end

end
