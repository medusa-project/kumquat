module ApplicationHelper

  CARD_IMAGE_SIZE = 512
  MAX_PAGINATION_LINKS = 9

  LOGGER = CustomLogger.new(ApplicationHelper)

  ##
  # Adds a full-window AJAX shade element to the DOM. This will be initially
  # hidden via CSS, and can be toggled on and off by
  # Application.AJAXShade.show() and hide() (JavaScript).
  #
  # @return [String]
  #
  def ajax_shade
    html = '<div id="dl-ajax-shade"></div>'
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
  # @param style [Symbol] `:check` or `:word`
  # @param invert_color [Boolean]
  # @param omit_color [Boolean]
  # @return [String]
  #
  def boolean(boolean, style: :check, invert_color: false, omit_color: false)
    if style == :check
      content = boolean ? '&check;' : '&times;'
      boolean = !boolean if invert_color
      class_  = boolean ? 'text-success' : 'text-danger'
      class_  = 'text-light' if omit_color
      html    = "<span class=\"#{class_}\">#{content}</span>"
    else
      content = boolean ? 'YES' : 'NO'
      boolean = !boolean if invert_color
      class_  = boolean ? 'badge-success' : 'badge-danger'
      class_  = 'badge-light' if omit_color
      html    = "<span class=\"badge #{class_}\">#{content}</span>"
    end
    raw(html)
  end

  ##
  # Renders the breadcrumb in public views. For admin views, see
  # {AdminHelper#admin_breadcrumb}.
  #
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
        return collection_view_breadcrumb(options[:collection])
      when 'items'
        case action_name
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
  # @param entities [Enumerable<Collection, Item>]
  # @return [String]
  #
  def entities_as_cards(entities)
    html = StringIO.new
    entities.each do |entity|
      bin = nil
      begin
        # If the entity is a Collection and the reference to the binary is
        # invalid (for example, an invalid UUID has been entered), this will
        # raise an error.
        bin = entity.effective_representative_image_binary
      rescue => e
        LOGGER.warn('entities_as_cards(): %s (%s)', e, entity)
      end

      if bin&.image_server_safe?
        img_url = binary_image_url(bin, region: 'square', size: CARD_IMAGE_SIZE)
      else
        case entity.class.to_s
          when 'Collection'
            img_url = image_url('fa-folder-open-o-600.png')
          else
            img_url = image_url('fa-cube-600.png')
        end
      end
      html << '<div class="dl-card">'
      html <<   '<div class="dl-card-content">'
      html <<     link_to(entity) do
        raw("<img src=\"#{img_url}\">")
      end
      html <<     '<h4 class="dl-title">'
      html <<       link_to(entity.title, entity)
      html <<     '</h4>'
      html <<   '</div>'
      html << '</div>'
    end
    raw(html.string)
  end

  ##
  # Returns a series of Bootstrap media elements for the given entities (Items,
  # Collections, Agents).
  #
  # @param entities [Enumerable<Representable>]
  # @param options [Hash] Hash with optional keys.
  # @option options [Boolean] :link_to_admin
  # @option options [Boolean] :show_collections
  # @option options [Boolean] :show_checkboxes
  # @option options [Boolean] :show_published_status
  # @return [String] HTML string.
  #
  def entities_as_media(entities, options = {})
    html = StringIO.new
    html << '<ul class="list-unstyled">'
    entities.each do |entity|
      html << '<li class="media my-4">'

      # Checkboxes
      if options[:show_checkboxes]
        html << '<div class="dl-checkbox-container">'
        html <<   check_box_tag('dl-selected-items[]', entity.repository_id)
        html << '</div>'
      end

      # Thumbnail area
      html <<   '<div class="dl-thumbnail-container">'

      if options[:link_to_admin] and entity.kind_of?(Item)
        link_target = admin_collection_item_path(entity.collection, entity)
      else
        link_target = polymorphic_path(entity)
      end
      html << link_to(link_target) do
        thumbnail_tag(entity.effective_representative_entity,
                      shape: :square)
      end
      # N.B.: this was made by https://loading.io with the following settings:
      # rolling, color: #cacaca, radius: 25, stroke width: 10, speed: 5, size: 150
      html <<   image_tag('thumbnail-spinner.svg', class: 'dl-load-indicator')
      html << '</div>'

      html << '<div class="media-body">'

      # Title line
      html <<   '<h5 class="mt-0">'
      html <<     link_to(entity.title, link_target)
      html <<   '</h5>'

      # Info line
      info_sections = []
      info_sections << "#{icon_for(entity)} #{type_of(entity)}"

      if entity.class.to_s == 'Item'
        num_pages = entity.pages.count
        if num_pages > 1
          page_count = "#{num_pages} pages"
          three_d_item = entity.three_d_item
          page_count += ' + 3D model' if three_d_item
          info_sections << page_count
        else
          num_files = entity.items.where(variant: Item::Variants::FILE).count
          if num_files > 0
            info_sections << "#{num_files} files"
          else
            num_children = entity.items.count
            if num_children > 0
              info_sections << "#{num_children} sub-items"
            end
          end
        end

        range = [
            entity.respond_to?(:date) ? entity.date : nil,
            entity.respond_to?(:end_date) ? entity.end_date : nil
        ]
        info_sections << range.select(&:present?).map(&:year).join('-') if range.any?

        if options[:show_collections] and entity.collection
          link_target = link_to(entity.collection.title,
                                collection_path(entity.collection))
          info_sections << "#{icon_for(entity.collection)} #{link_target}"
        end
      end

      if options[:show_published_status] and entity.respond_to?(:published)
        if entity.published
          info_sections << '<span class="badge badge-success"><i class="fa fa-check"></i> Published</span>'
        else
          info_sections << '<span class="badge badge-danger"><i class="fa fa-lock"></i> Unpublished</span>'
        end
      end

      html << '<span class="dl-info-line">'
      html <<   info_sections.join(' | ')
      html << '</span>'
      html << '<span class="dl-description">'

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
    html << '</ul>'
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
      html << facet_card(facet, params.permit(permitted_params))
    end
    raw(html.string)
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
      html << "<div class=\"dl-flash alert alert-dismissable #{bootstrap_class_for(type)}\">"
      html <<   '<button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>'
      html <<   message
      html << '</div>'
    end
    raw(html.string)
  end

  ##
  # N.B.: {icon_for} should generally be used instead.
  #
  def fontawesome_icon_for(entity)
    icon = %w(fas cube)
    if entity == Item
      icon = %w(fas cube)
    elsif entity.kind_of?(Item)
      viewer_binary = entity.effective_viewer_binary
      if viewer_binary&.is_audio?
        icon = %w(fas volume-up)
      elsif viewer_binary&.is_image?
        icon = %w(far image)
      elsif viewer_binary&.is_pdf?
        icon = %w(far file-pdf)
      elsif viewer_binary&.is_text? or viewer_binary&.is_document?
        icon = %w(far file-alt)
      elsif viewer_binary&.is_video?
        icon = %w(fas film)
      elsif entity.variant == Item::Variants::DIRECTORY
        icon = %w(far folder-open)
      elsif entity.variant == Item::Variants::FILE
        icon = %w(far file)
      elsif entity.items.any?
        icon = %w(fas cubes)
      end
    elsif entity.kind_of?(Binary)
      if entity.is_audio?
        icon = %w(fas volume-up)
      elsif entity.is_image?
        icon = %w(fas image)
      elsif entity.is_pdf?
        icon = %w(far file-pdf)
      elsif entity.is_text? or entity.is_document?
        icon = %w(far file-alt)
      elsif entity.is_video?
        icon = %w(fas film)
      end
    elsif entity == Collection or entity.kind_of?(Collection)
      icon = %w(far folder-open)
    elsif entity == Agent or entity.kind_of?(Agent)
      icon = %w(fas user-circle)
    elsif entity == ItemSet or entity.kind_of?(ItemSet)
      icon = %w(far circle)
    elsif entity == User or entity.kind_of?(User)
      icon = %w(fas user)
    end
    icon
  end

  ##
  # Returns the most appropriate icon for the given object, which may be an
  # Item, Binary, Collection, etc. If the object is unrecognized, a generic
  # icon is returned.
  #
  # @param entity [Object]
  # @return [String] HTML `i` tag.
  #
  def icon_for(entity)
    icon = fontawesome_icon_for(entity)
    raw("<i class=\"#{icon[0]} fa-#{icon[1]}\" aria-hidden=\"true\"></i>")
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
  # Returns a deferred img tag (with `data-src` set instead of `src`) for
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
  # @param total_entities [Integer]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param permitted_params [ActionController::Parameters,Enumerable<Symbol>]
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
    unless permitted_params.kind_of?(ActionController::Parameters)
      permitted_params = params.permit(permitted_params)
    end

    first_link = link_to(permitted_params.except(:start),
                         remote: remote, class: 'page-link', 'aria-label': 'First') do
      raw('<span aria-hidden="true">First</span>')
    end
    prev_link = link_to(permitted_params.merge(start: prev_start),
                        remote: remote, class: 'page-link', 'aria-label': 'Previous') do
      raw('<span aria-hidden="true">&laquo;</span>')
    end
    next_link = link_to(permitted_params.merge(start: next_start),
                        remote: remote, class: 'page-link', 'aria-label': 'Next') do
      raw('<span aria-hidden="true">&raquo;</span>')
    end
    last_link = link_to(permitted_params.merge(start: last_start),
                        remote: remote, class: 'page-link', 'aria-label': 'Last') do
      raw('<span aria-hidden="true">Last</span>')
    end

    html = StringIO.new
    html << '<nav>'
    html <<   '<ul class="pagination">'
    html <<     "<li class=\"page-item #{current_page == first_page ? 'disabled' : ''}\">#{first_link}</li>"
    html <<     "<li class=\"page-item #{current_page == prev_page ? 'disabled' : ''}\">#{prev_link}</li>"
    (first_page..last_page).each do |page|
      start = (page - 1) * per_page
      page_link = link_to((start == 0) ? permitted_params.except(:start) : permitted_params.merge(start: start),
                          remote: remote, class: 'page-link') do
        raw("#{page} #{(page == current_page) ?
            '<span class="sr-only">(current)</span>' : ''}")
      end
      html << "<li class=\"page-item #{page == current_page ? 'active' : ''}\">"
      html <<   page_link
      html << '</li>'
    end
    html <<     "<li class=\"page-item #{current_page == next_page ? 'disabled' : ''}\">#{next_link}</li>"
    html <<     "<li class=\"page-item #{current_page == last_page ? 'disabled' : ''}\">#{last_link}</li>"
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
        image = '<i class="far fa-copyright fa-fw fa-3x"></i>'
      end

      title = statement ? '' : '<h4 class="media-heading">Rights Information</h4>'
      text = text.present? ? "<p>#{auto_link(text)}</p>" : ''

      html << '<div class="media dl-rights">'
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
  # @param entity [Object]
  # @return [String] Text description of the entity's type
  #
  def type_of(entity)
    type = 'Item'
    if entity == Item
      type = 'Item'
    elsif entity.kind_of?(Item)
      viewer_binary = entity.effective_viewer_binary
      if entity.pages.count > 1
        type = 'Multi-Page Item'
      elsif viewer_binary&.is_3d?
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
      html << '<li class="breadcrumb-item">'
      html <<   link_to(parent.title, parent)
      html << '</li>'
      html << html.string
      parent = parent.parents.first
    end
    html << '<li class="breadcrumb-item active" aria-current="page">'
    html <<   truncate(collection.title, length: 50)
    html << '</li>'
    html.string
  end

  def collection_view_breadcrumb(collection)
    html = StringIO.new
    html << '<nav aria-label="breadcrumb">'
    html <<   '<ol class="breadcrumb">'
    html <<     '<li class="breadcrumb-item">'
    html <<       link_to('Home', root_path)
    html <<     '</li>'
    html <<     '<li class="breadcrumb-item">'
    html <<       repository_link(collection)
    html <<     '</li>'
    html <<     collection_structure_breadcrumb(collection)
    html <<   '</ol>'
    html << '</nav>'
    raw(html.string)
  end

  ##
  # @param facet [Facet]
  #
  def facet_card(facet, permitted_params)
    panel = StringIO.new
    panel << "<div class=\"card dl-facet\" id=\"#{facet.field}\">"
    panel <<   "<h5 class=\"card-header\">#{facet.name}</h5>"
    panel <<     '<div class="card-body">'
    panel <<       '<ul>'
    facet.terms.each do |term|
      checked = (params[:fq] and params[:fq].include?(term.query)) ?
                    'checked' : nil
      checked_params = term.removed_from_params(permitted_params.deep_dup).except(:start)
      unchecked_params = term.added_to_params(permitted_params.deep_dup).except(:start)
      term_label = truncate(term.label, length: 80)

      panel << '<li class="dl-term">'
      panel <<   '<div class="checkbox">'
      panel <<     '<label>'
      panel <<       "<input type=\"checkbox\" name=\"dl-facet-term\" #{checked} "\
                         "data-query=\"#{term.query.gsub('"', '&quot;')}\" "\
                         "data-checked-href=\"#{url_for(unchecked_params)}\" "\
                         "data-unchecked-href=\"#{url_for(checked_params)}\"> "
      panel <<         "<span class=\"dl-term-name\">#{term_label}</span> "
      panel <<         "<span class=\"dl-count\">#{term.count}</span>"
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
      html << '<li class="breadcrumb-item">'
      html <<   link_to(parent.title, parent)
      html << '</li>'
      html << html.string
      parent = parent.parent
    end
    html << '<li class="breadcrumb-item active">'
    html <<   truncate(item.title, length: 50)
    html << '</li>'
    html.string
  end

  def item_view_breadcrumb(item, context, context_url)
    html = StringIO.new
    html << '<nav aria-label="breadcrumb">'
    html <<   '<ol class="breadcrumb">'
    case context
      when ItemsController::BrowseContext::SEARCHING
        html << '<li class="breadcrumb-item">'
        html <<   link_to('Home', root_path)
        html << '</li>'
        html << '<li class="breadcrumb-item">'
        html <<   link_to('Search', context_url)
        html << '</li>'
        html << item_structure_breadcrumb(item)
      when ItemsController::BrowseContext::BROWSING_ALL_ITEMS
        html << '<li class="breadcrumb-item">'
        html <<   link_to('Home', root_path)
        html << '</li>'
        html << '<li class="breadcrumb-item">'
        html <<   link_to('All Items', items_path)
        html << '</li>'
        html << item_structure_breadcrumb(item)
      else
        html << '<li class="breadcrumb-item">'
        html <<   link_to('Home', root_path)
        html << '</li>'
        if item.collection
          html << '<li class="breadcrumb-item">'
          html <<   repository_link(item.collection)
          html << '</li>'
          html << '<li class="breadcrumb-item">'
          html <<   link_to(item.collection.title, collection_path(item.collection))
          html << '</li>'
          html << '<li class="breadcrumb-item">'
          html <<   link_to('Items', collection_items_path(item.collection))
          html << '</li>'
        else
          html << '<li class="breadcrumb-item">Unknown Repository</li>'
          html << '<li class="breadcrumb-item">Unknown Collection</li>'
        end
        html << item_structure_breadcrumb(item)
    end
    html <<   '</ol>'
    html << '</nav>'
    raw(html.string)
  end

  def results_breadcrumb(collection, context)
    if context == ItemsController::BrowseContext::BROWSING_COLLECTION
      html = StringIO.new
      html << '<nav aria-label="breadcrumb">'
      html <<   '<ol class="breadcrumb">'
      html <<     '<li class="breadcrumb-item">'
      html <<       link_to('Home', root_path)
      html <<     '<li class="breadcrumb-item">'
      html <<       repository_link(collection)
      html <<     '</li>'
      html <<     '<li class="breadcrumb-item">'
      html <<       link_to(truncate(collection.title, length: 50), collection_path(collection))
      html <<     '</li>'
      html <<     '<li class="breadcrumb-item active" aria-current="page">Items</li>'
      html <<   '</ol>'
      html << '</nav>'
      raw(html.string)
    end
  end

end
