module ApplicationHelper

  CARD_IMAGE_SIZE      = 512
  MAX_PAGINATION_LINKS = 9
  CAPTCHA_SALT         = ::Configuration.instance.secret_key_base

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
  # @param boolean [Boolean] Boolean value.
  # @param style [Symbol] `:check` or `:word`
  # @param invert_color [Boolean] Shows true in red and false in green.
  # @param omit_color [Boolean]
  # @param true_string [String] Alternative to `YES`.
  # @param false_string [String] Alternative to `NO`.
  # @return [String]
  #
  def boolean(boolean,
              style:          :check,
              invert_color:   false,
              omit_color:     false,
              true_string:    nil,
              false_string:   nil)
    style = :word if true_string.present? || false_string.present?
    if style == :check
      content = boolean ? '&check;' : '&times;'
      boolean = !boolean if invert_color
      class_  = boolean ? 'text-success' : 'text-danger'
      class_  = 'text-light' if omit_color
      html    = "<span class=\"#{class_}\">#{content}</span>"
    else
      content = if boolean
                  true_string.present? ? true_string : 'YES'
                else
                  false_string.present? ? false_string : 'NO'
                end
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
  # @param collection [Collection]
  # @param item [Item]
  # @param context [ItemsController::BrowseContext]
  # @param context_url [String]
  # @return [String]
  #
  def breadcrumb(collection: nil, item: nil, context: nil, context_url: nil)
    case controller_name
      when 'collections'
        return collection_view_breadcrumb(collection)
      when 'items'
        case action_name
          when 'index', 'tree'
            return results_breadcrumb(collection, context)
          when 'show'
            return item_view_breadcrumb(item, context, context_url)
        end
    end
    nil
  end

  ##
  # Returns a CAPTCHA form.
  #
  # This is typically used in a modal in conjunction with the
  # `Application.CaptchaProtectedDownload()` JavaScript function.
  #
  # @param form_action [String] URL or URL path to submit the form to. This is
  #                             typically the same as what a non-CAPTCHA-
  #                             protected link would be pointing to.
  # @param block [Block]        Additional HTML content to insert into the
  #                             form.
  # @return [String]            HTML form string.
  #
  def captcha 
    field_html = StringIO.new
    number1     = rand(9)
    number2     = rand(9)
    answer_hash = Digest::MD5.hexdigest((number1 + number2).to_s + CAPTCHA_SALT)
    label_html  = label_tag(:answer, raw("What is #{number1} &plus; #{number2}?"),
                          class: "col-sm-3 col-form-label")
    field_html << text_field_tag(:honey_email, nil,
                                placeholder: "Leave this field blank.",
                                style:       "display: none") # honeypot field
    field_html << text_field_tag(:answer, nil, class: "form-control")
    field_html << hidden_field_tag(:correct_answer_hash, answer_hash)
    {
      label: raw(label_html),
      field: raw(field_html.string)
    }
  end

  ##
  # @param entity [Item,Collection]
  # @return [String, nil] Mailto string for injection into an anchor href, or
  #                       nil if the collection's repository does not have a
  #                       contact email.
  #
  def curator_mailto(entity)
    mailto     = nil
    collection = entity.kind_of?(Item) ? entity.collection : entity
    # Communication with Medusa may raise an IOError (see rescue block)
    email      = collection&.medusa_repository&.email
    if email.present?
      # https://bugs.library.illinois.edu/browse/DLD-89
      website_name = Setting::string(Setting::Keys::WEBSITE_NAME)
      subject      = sprintf('%s: %s', website_name, entity.title)
      body         = StringIO.new
      body         << "This email was sent to you from the #{website_name} "\
                      "by a patron wishing to contact the curator of the following "
      body         << (entity.kind_of?(Collection) ? "collection" : "item")
      body         << " for more information:%0D%0D"
      body         << (entity.kind_of?(Collection) ? collection_url(entity) : item_url(entity))
      body         << "%0D%0D(Enter your comment here.)%0D"
      mailto       = "mailto:#{email}?subject=#{subject}&body=#{body.string}"
    end
    mailto
  rescue IOError
    # It's still possible to render the page.
    '#'
  end

  ##
  # @param entities [Enumerable<Collection, Item>]
  # @return [String]
  #
  def entities_as_cards(entities)
    html = StringIO.new
    entities.each do |entity|
      rep = entity.effective_file_representation
      case rep.type
      when Representation::Type::MEDUSA_FILE && rep.file
        img_url = ImageServer.file_image_v2_url(file:   rep.file,
                                                region: 'square',
                                                size:   CARD_IMAGE_SIZE)
      when Representation::Type::LOCAL_FILE && rep.key
        img_url = ImageServer.s3_image_v2_url(bucket: KumquatS3Client::BUCKET,
                                              key:    rep.key,
                                              region: 'square',
                                              size:   CARD_IMAGE_SIZE)
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
  # @param show_collections [Boolean] Relevant only when the given entities are
  #                                   [Item]s.
  # @return [String] HTML string.
  #
  def entities_as_media(entities, show_collections: false)
    html = StringIO.new
    html << '<ul class="list-unstyled">'
    entities.each do |entity|
      html << '<li class="media my-4">'

      # Thumbnail area
      html <<   '<div class="dl-thumbnail-container">'
      link_target = polymorphic_path(entity)
      html << link_to(link_target) do
        thumbnail_tag(entity, shape: :square)
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

        if show_collections && entity.collection
          link_target = link_to(entity.collection.title,
                                collection_path(entity.collection))
          info_sections << "#{icon_for(entity.collection)} #{link_target}"
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
  def facets_as_cards(facets, permitted_params)
    return nil unless facets&.any?
    html = StringIO.new
    facets.select{ |f| f.terms.any? }.each do |facet|
      html << facet_card(facet, params.permit(permitted_params))
      html << facet_modal(facet, params.permit(permitted_params))
    end
    raw(html.string)
  end

  def feedback_link
    subject = 'Feedback on ' + Setting::string(Setting::Keys::WEBSITE_NAME)
    body = 'Page URL: ' + request.url
    url = sprintf('mailto:%s?subject=%s&body=%s',
                  Setting::string(Setting::Keys::ADMINISTRATOR_EMAIL),
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
    if entity == :info
      icon = %w[fas info-circle]
    elsif entity == Item
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
    elsif entity == Collection || entity.kind_of?(Collection)
      icon = %w(far folder-open)
    elsif entity == Agent || entity.kind_of?(Agent)
      icon = %w(fas user-circle)
    elsif entity == ItemSet || entity.kind_of?(ItemSet)
      icon = %w(far circle)
    elsif entity == User || entity.kind_of?(User)
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
  # @param options [Hash] Additional HTML tag attributes.
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
  # @param total_entities [Integer] Total number of entities/results to
  #                                 paginate through. This will be limited
  #                                 internally to
  #                                 {OpensearchClient#MAX_RESULT_WINDOW}.
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param permitted_params [ActionController::Parameters,Enumerable<Symbol>]
  # @param remote [Boolean]
  # @param max_links [Integer] (ideally odd)
  #
  def paginate(total_entities, per_page, current_page, permitted_params,
               remote = false, max_links = MAX_PAGINATION_LINKS)
    total_entities = [total_entities, OpensearchClient::MAX_RESULT_WINDOW].min
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
  # @param entity [Object] Object to authorize.
  # @return [ApplicationPolicy] Policy class associated with the current
  #                             controller.
  #
  def policy(entity)
    if entity.is_a?(Symbol)
      class_ = entity.to_s.camelize
    elsif entity.is_a?(Class)
      class_ = entity.to_s
    else
      class_ = entity.class.to_s
    end
    class_   += "Policy"
    ctrl_path = controller_path.split("/")
    namespace = (ctrl_path.length > 1) ? ctrl_path.first : ""
    class_    = [namespace.camelize, class_].join("::")
    class_.constantize.new(current_user, entity)
  end

  ##
  # @param term [VocabularyTerm, nil]
  # @param text [String, nil]
  # @return [String]
  #
  def rights_statement(term, text)
    html = StringIO.new
    if term&.vocabulary && term&.info_uri
      image = link_to(term.info_uri, target: '_blank') do
        image_tag(term.image, alt: "#{term.string} (#{term.vocabulary.name})")
      end
    elsif text.present?
      image = '<i class="far fa-copyright fa-fw fa-3x"></i>'
    else
      return html.string
    end

    title = term ? '' : '<h4 class="media-heading">Rights Information</h4>'
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

    raw(html.string)
  end

  def spinner
    raw('<div class="d-flex justify-content-center align-items-center" style="height: 100%">
      <div class="spinner-border text-secondary" role="status">
        <span class="sr-only">Loading&hellip;</span>
      </div>
    </div>')
  end

  ##
  # @param entity [Binary, Representable, Medusa::File] See above.
  # @param shape [Symbol] `:full` or `:square`.
  # @param size [Integer]
  # @param lazy [Boolean] If true, the `data-src` attribute will be set instead
  #                       of `src`; defaults to false.
  # @param representation_type [String] One of the [Representation::Type]
  #                                     constant values.
  # @return [String]
  #
  def thumbnail_tag(entity,
                    shape:               :full,
                    size:                ItemsHelper::DEFAULT_THUMBNAIL_SIZE,
                    lazy:                false,
                    representation_type: nil)
    rep_entity = entity
    if entity.class.include?(Representable)
      rep      = entity.effective_file_representation
      rep_type = representation_type || rep.type
      case rep_type
      when Representation::Type::MEDUSA_FILE
        rep_entity = rep.file
      when Representation::Type::LOCAL_FILE
        rep_entity = rep.key
      end
    end

    url = nil
    if rep_entity.kind_of?(Medusa::File)
      url = ImageServer.file_image_v2_url(file:   rep_entity,
                                          region: shape,
                                          size:   size)
    elsif rep_entity.kind_of?(Binary)
      url = ImageServer.binary_image_v2_url(binary: rep_entity,
                                            region: shape,
                                            size:   size)
    elsif rep_entity.kind_of?(Item)
      url = item_image_url(item:   rep_entity,
                           region: shape,
                           size:   size)
    elsif rep_entity.kind_of?(String)
      url = ImageServer.s3_image_v2_url(bucket: KumquatS3Client::BUCKET,
                                        key:    rep_entity,
                                        region: shape,
                                        size:   size)
    end

    html = StringIO.new
    if url
      # No alt because it may appear in a huge font size if the image is 404. TODO: is this still the case?
      if lazy
        html << lazy_image_tag(url, class: 'dl-thumbnail mr-3', alt: '')
      else
        html << image_tag(url, class: 'dl-thumbnail mr-3', alt: '',
                          data: { location: 'remote' })
      end
    else
      # N.B.: instead of using ApplicationHelper.icon_for(), we have
      # pre-downloaded some Font Awesome icons as SVGs and saved in them in the
      # assets directory. This results in them appearing in <img> tags which
      # helps make our CSS more concise. The files are available at:
      # https://github.com/encharm/Font-Awesome-SVG-PNG/tree/master/black/svg
      html << image_tag('fontawesome-' + fontawesome_icon_for(entity)[1] + '.svg',
                        'data-type':     'svg',
                        'data-location': 'local')
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
  # @param permitted_params [ActionController::Parameters]
  # @private
  #
  def facet_card(facet, permitted_params)
    max_terms = Setting.integer(Setting::Keys::FACET_TERM_LIMIT, 20)
    panel = StringIO.new
    panel << "<div class=\"card dl-card-facet\" id=\"#{facet.field}-card\">"
    panel <<   '<h5 class="card-header">'
    panel <<     facet.name
    panel <<   '</h5>'
    panel <<   '<div class="card-body">'
    panel <<     '<ul>'
    facet.terms[0..max_terms].each do |term|
      checked          = (params[:fq] && params[:fq].include?(term.query)) ?
                           'checked' : nil
      checked_params   = term.removed_from_params(permitted_params.deep_dup).except(:start)
      unchecked_params = term.added_to_params(permitted_params.deep_dup).except(:start)
      term_label       = truncate(term.label, length: 80)
      panel <<     '<li class="dl-term">'
      panel <<       '<div class="checkbox">'
      panel <<         '<label>'
      panel <<           "<input type=\"checkbox\" name=\"dl-facet-term\" #{checked} "\
                             "data-query=\"#{term.query.gsub('"', '&quot;')}\" "\
                             "data-checked-href=\"#{url_for(unchecked_params)}\" "\
                             "data-unchecked-href=\"#{url_for(checked_params)}\"> "
      panel <<             "<span class=\"dl-term-name\">#{term_label}</span> "
      panel <<             "<span class=\"dl-count\">#{term.count}</span>"
      panel <<         '</label>'
      panel <<       '</div>'
      panel <<     '</li>'
    end
    panel <<     '</ul>'
    panel <<   '</div>' # card-body
    if facet.terms.length >= max_terms
      panel << "<button type=\"button\" class=\"btn btn-text dl-more-button\"
                    data-toggle=\"modal\" data-target=\"##{facet.field.gsub(/[^A-Za-z\d]/, "-")}-modal\">"
      panel <<   'View All Options&hellip;'
      panel << '</button>'
    end
    panel << '</div>' # card
    raw(panel.string)
  end

  ##
  # @param facet [Facet]
  # @param permitted_params [ActionController::Parameters]
  # @private
  #
  def facet_modal(facet, permitted_params)
    modal_id = "#{facet.field.gsub(/[^A-Za-z\d]/, "-")}-modal"
    panel = StringIO.new
    panel << "<div class=\"modal fade dl-modal-facet\" id=\"#{modal_id}\"
              tabindex=\"-1\" aria-labelledby=\"#{modal_id}-label\"
              aria-hidden=\"true\">"
    panel <<   "<div class=\"modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable\">"
    panel <<     "<div class=\"modal-content\">"
    panel <<       "<div class=\"modal-header\">"
    panel <<         "<h5 class=\"modal-title fs-5\" id=\"#{modal_id}-label\">"
    panel <<           facet.name
    panel <<         "</h5>"
    panel <<         "<button type=\"button\" class=\"close\"
                      data-dismiss=\"modal\" aria-label=\"Close\">"
    panel <<           '<span aria-hidden="true">&times;</span>'
    panel <<         "</button>"
    panel <<       "</div>"
    panel <<       "<div class=\"modal-body\">"
    panel <<         "<div class=\"alert alert-light\">"
    panel <<           icon_for(:info)
    panel <<           " Select a term to narrow your results."
    panel <<         "</div>"
    panel <<         "<ul>"
    # natural_sort gem
    facet.terms.sort_by{ |term| NaturalSort(term.label) }.each do |term|
      checked = (params[:fq] and params[:fq].include?(term.query)) ?
                  'checked' : nil
      checked_params   = term.removed_from_params(permitted_params.deep_dup).except(:start)
      unchecked_params = term.added_to_params(permitted_params.deep_dup).except(:start)
      panel <<         '<li class="dl-term">'
      panel <<           '<div class="checkbox">'
      panel <<             '<label>'
      panel <<               "<input type=\"radio\" name=\"dl-facet-term\" #{checked} "\
                               "data-query=\"#{term.query.gsub('"', '&quot;')}\" "\
                               "data-checked-href=\"#{url_for(unchecked_params)}\" "\
                               "data-unchecked-href=\"#{url_for(checked_params)}\"> "
      panel <<               "<span class=\"dl-term-name\">#{term.label}</span> "
      panel <<               "<span class=\"dl-count\">#{term.count}</span>"
      panel <<             '</label>'
      panel <<           '</div>'
      panel <<         '</li>'
    end
    panel <<         '</ul>'
    panel <<       '</div>' # modal-body
    panel <<       '<div class="modal-footer">'
    panel <<         '<button type="button" class="btn btn-light" data-dismiss="modal">Close</button>'
    panel <<         '<button type="button" class="btn btn-primary submit">Apply Changes</button>'
    panel <<       '</div>'
    panel <<     '</div>' # modal-content
    panel <<   '</div>' # modal-dialog
    panel << '</div>' # modal
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
