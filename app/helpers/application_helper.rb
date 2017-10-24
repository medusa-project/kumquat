module ApplicationHelper

  MAX_PAGINATION_LINKS = 9

  ##
  # Adds a full-window AJAX shade element to the DOM. This will be initially
  # hidden via CSS, and can be toggled on and off by PearTree.AJAXShade.show()
  # and hide().
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
  # Returns an ordered list of the given entities (Items, Collections, Agents).
  #
  # @param entities [Enumerable<Representable>]
  # @param start [integer] Offset.
  # @param options [Hash] Hash with optional keys.
  # @option options [Boolean] :link_to_admin
  # @option options [Boolean] :show_remove_from_favorites_buttons
  # @option options [Boolean] :show_add_to_favorites_buttons
  # @option options [Boolean] :show_collections
  # @option options [Boolean] :show_checkboxes
  # @return [String] HTML string.
  #
  def entities_as_list(entities, start, options = {})
    html = "<ol start=\"#{start + 1}\">"
    entities.each do |entity|
      if options[:link_to_admin] and entity.kind_of?(Item)
        link_target = admin_collection_item_path(entity.collection, entity)
      else
        link_target = polymorphic_path(entity)
      end
      html += '<li>'
      if options[:show_checkboxes]
        html += check_box_tag('pt-selected-items[]', entity.repository_id)
        html += '<div class="pt-checkbox-result-container">'
      else
        html += '<div class="pt-non-checkbox-result-container">'
      end
      html += link_to(link_target, class: 'pt-thumbnail-link') do
        raw('<div class="pt-thumbnail">' +
                thumbnail_tag(entity.effective_representative_entity,
                              shape: :square) +
                '</div>')
      end
      html += '<span class="pt-label">'
      html += link_to(entity.title, link_target)

      # info line
      info_parts = []
      info_parts << "#{icon_for(entity)}#{type_of(entity)}"

      if entity.kind_of?(Item)
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
  # @param facets [Enumerable<Facet>]
  # @param permitted_params [ActionController::Parameters]
  # @return [String] HTML string
  #
  def facets_as_panels(facets, permitted_params)
    return nil unless facets
    html = ''
    facets.select{ |f| f.terms.any? }.each do |facet|
      html += facet_panel(facet, params.permit(permitted_params))
    end
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
    html = ''
    flash.each do |type, message|
      html += "<div class=\"pt-flash alert alert-dismissable #{bootstrap_class_for(type)}\">
          <button type=\"button\" class=\"close\" data-dismiss=\"alert\"
                  aria-hidden=\"true\">&times;</button>
          #{message}
        </div>"
    end
    raw(html)
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
      if entity.effective_image_binary&.is_audio?
        icon = 'fa-volume-up'
      elsif entity.effective_image_binary&.is_image?
        icon = 'fa-picture-o'
      elsif entity.effective_image_binary&.is_document?
        icon = 'fa-file-pdf-o'
      elsif entity.effective_image_binary&.is_text?
        icon = 'fa-file-text-o'
      elsif entity.effective_image_binary&.is_video?
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
      html += '<p>No results.</p>'
    end
    raw(html)
  end

  ##
  # @param entities [ActiveRecord::Relation]
  # @param total_entities [Integer]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param remote [Boolean]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate(total_entities, per_page, current_page, remote = false,
               max_links = MAX_PAGINATION_LINKS)
    return '' if total_entities <= per_page
    num_pages = (total_entities / per_page.to_f).ceil
    first_page = [1, current_page - (max_links / 2.0).floor].max
    last_page = [first_page + max_links - 1, num_pages].min
    first_page = last_page - max_links + 1 if
        last_page - first_page < max_links and num_pages > max_links
    prev_page = [1, current_page - 1].max
    next_page = [last_page, current_page + 1].min
    prev_start = (prev_page - 1) * per_page
    next_start = (next_page - 1) * per_page
    last_start = (num_pages - 1) * per_page

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

    # http://getbootstrap.com/components/#pagination
    html = '<nav>' +
        '<ul class="pagination">' +
        "<li #{current_page == first_page ? 'class="disabled"' : ''}>#{first_link}</li>" +
        "<li #{current_page == prev_page ? 'class="disabled"' : ''}>#{prev_link}</li>"
    (first_page..last_page).each do |page|
      start = (page - 1) * per_page
      page_link = link_to((start == 0) ? params.except(:start) :
                              params.merge(start: start).symbolize_keys, remote: remote) do
        raw("#{page} #{(page == current_page) ?
            '<span class="sr-only">(current)</span>' : ''}")
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
  # @param statement [RightsStatement, nil]
  # @param text [String, nil]
  # @return [String]
  #
  def rights_statement(statement, text)
    html = ''
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

      html += "<div class=\"media pt-rights\">
          <div class=\"media-left\">
            #{image}
          </div>
          <div class=\"media-body\">
            #{title}#{text}
          </div>
        </div>"
    end
    raw(html)
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
      if entity.effective_image_binary&.is_3d?
        type = '3D'
      elsif entity.effective_image_binary&.is_audio?
        type = 'Audio'
      elsif entity.effective_image_binary&.is_image?
        type = 'Image'
      elsif entity.effective_image_binary&.is_document?
        type = 'Document'
      elsif entity.effective_image_binary&.is_text?
        type = 'Text'
      elsif entity.effective_image_binary&.is_video?
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
    html = ''
    parent = collection.parents.first
    while parent
      html = "<li>#{link_to parent.title, parent}</li>#{html}"
      parent = parent.parents.first
    end
    html += "<li class=\"active\">#{truncate(collection.title, length: 50)}</li>"
    html
  end

  def collection_view_breadcrumb(collection)
    html = "<ol class=\"breadcrumb\">"\
      "<li>#{link_to 'Home', root_path}</li>"\
      "<li>#{repository_link(collection)}</li>"
    html += collection_structure_breadcrumb(collection)
    html += '</ol>'
    raw(html)
  end

  ##
  # @param facet [Facet]
  #
  def facet_panel(facet, permitted_params)
    panel = "<div class=\"panel panel-default\" id=\"#{facet.field}\">
      <div class=\"panel-heading\">
        <h3 class=\"panel-title\">#{facet.name}</h3>
      </div>
      <div class=\"panel-body\">
        <ul>"
    facet.terms[0..Option::integer(Option::Keys::FACET_TERM_LIMIT)].each do |term|
      checked = (params[:fq] and params[:fq].include?(term.query)) ?
                    'checked' : nil
      checked_params = term.removed_from_params(permitted_params.deep_dup).except(:start)
      unchecked_params = term.added_to_params(permitted_params.deep_dup).except(:start)
      term_label = truncate(term.label, length: 80)

      panel += "<li class=\"pt-term\">"\
               "  <div class=\"checkbox\">"\
               "    <label>"\
               "      <input type=\"checkbox\" name=\"pt-facet-term\" #{checked} "\
               "          data-query=\"#{term.query.gsub('"', '&quot;')}\" "\
               "          data-checked-href=\"#{url_for(unchecked_params)}\" "\
               "          data-unchecked-href=\"#{url_for(checked_params)}\">"\
               "      <span class=\"pt-term-name\">#{term_label}</span> "\
               "      <span class=\"pt-count badge\">#{term.count}</span>"\
               "    </label>"\
               "  </div>"\
               "</li>"
    end
    raw(panel + '</ul></div></div>')
  end

  def item_structure_breadcrumb(item)
    html = ''
    parent = item.parent
    while parent
      html = "<li>#{link_to parent.title, parent}</li>#{html}"
      parent = parent.parent
    end
    html += "<li class=\"active\">#{truncate(item.title, length: 50)}</li>"
    html
  end

  def item_view_breadcrumb(item, context, context_url)
    case context
      when ItemsController::BrowseContext::SEARCHING
        html = "<ol class=\"breadcrumb\">"
        html += "<li>#{link_to 'Home', root_path}</li>"
        html += "<li>#{link_to 'Search', context_url}</li>"
        html += item_structure_breadcrumb(item)
        html += "</ol>"
      when ItemsController::BrowseContext::BROWSING_ALL_ITEMS
        html = "<ol class=\"breadcrumb\">"
        html += "<li>#{link_to 'Home', root_path}</li>"
        html += "<li>#{link_to 'All Items', items_path}</li>"
        html += item_structure_breadcrumb(item)
        html += "</ol>"
      when ItemsController::BrowseContext::FAVORITES
        html = "<ol class=\"breadcrumb\">"
        html += "<li>#{link_to 'Home', root_path}</li>"
        html += "<li>#{link_to 'Favorites', favorites_path}</li>"
        html += item_structure_breadcrumb(item)
        html += "</ol>"
      else
        html = "<ol class=\"breadcrumb\">"
        html += "<li>#{link_to 'Home', root_path}</li>"
        html += "<li>#{repository_link(item.collection)}</li>"
        html += "<li>#{link_to item.collection.title, collection_path(item.collection)}</li>"
        html += "<li>#{link_to 'Items', collection_items_path(item.collection)}</li>"
        html += item_structure_breadcrumb(item)
        html += "</ol>"
    end
    raw(html)
  end

  def repository_link(collection)
    fq = "#{Collection::IndexFields::REPOSITORY_TITLE}:#{collection.medusa_repository.title}"
    link_to collection.medusa_repository.title, collections_path('fq[]': fq)
  end

  def results_breadcrumb(collection, context)
    if context == ItemsController::BrowseContext::BROWSING_COLLECTION
      html = "<ol class=\"breadcrumb\">"\
                "<li>#{link_to('Home', root_path)}</li>"\
                "<li>#{repository_link(collection)}</li>"\
                "<li>#{link_to(truncate(collection.title, length: 50), collection_path(collection))}</li>"\
                "<li class=\"active\">Items</li>"\
              "</ol>"
      return raw(html)
    end
  end

end
