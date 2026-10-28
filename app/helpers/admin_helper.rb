module AdminHelper

  ##
  # @param items [Enumerable<Hash>] Enumerable of hashes with `:label` and
  #                                 `:url` keys.
  # @return [String] HTML string
  #
  def admin_breadcrumb(*items)
    html = StringIO.new
    html << '<nav aria-label="breadcrumb">'
    html <<   '<ol class="breadcrumb">'
    items.each_with_index do |item, index|
      if item.kind_of?(String)
        html << item
      elsif index < items.length - 1
        html << sprintf('<li class="breadcrumb-item"><a href="%s">%s</a></li>',
                        item[:url], item[:label])
      else
        html << sprintf('<li class="breadcrumb-item active" aria-current="page">%s</li>',
                        item[:label])
      end
    end
    html <<   '</ol>'
    html << '</nav>'
    raw(html.string)
  end

  ##
  # @param collection [Collection]
  # @return [String]
  #
  def admin_collection_tree(collection)
    child_html = StringIO.new
    if collection.children.count > 0
      child_html << '<ul>'
      collection.children.each do |child|
        child_html << '<li>'
        child_html <<   link_to(child.title, admin_collection_path(child))
        child_html << '</li>'
      end
      child_html << '</ul>'
    end

    parent_html = StringIO.new
    if collection.parents.count > 0
      collection.parents.each do |parent|
        parent_html << '<li>'
        parent_html <<   link_to(parent.title, admin_collection_path(parent))
        parent_html << '</li>'
      end
    end

    html = StringIO.new
    if parent_html.present?
      html << '<ul>'
      html <<   parent_html.string
      html <<   '<ul>'
      html <<     '<li>'
      html <<       collection.title
      html <<       child_html.string
      html <<     '</li>'
      html <<   '</ul>'
    elsif child_html.present?
      html << '<ul>'
      html <<   '<li>'
      html <<     collection.title
      html <<     child_html.string
      html <<   '</li>'
      html << '</ul>'
    end
    raw(html.string)
  end

  ##
  # @param profile_element [MetadataProfileElement]
  # @param element [ItemElement, nil]
  # @param vocabulary [Vocabulary]
  # @return [String]
  #
  def admin_item_element_edit_tag(profile_element, element, vocabulary)
    html = StringIO.new
    html << '<table class="table-sm dl-element" style="width:100%">'
    html <<   '<tr>'
    html <<     '<th style="text-align: right; width: 1px">'
    html <<       '<span class="badge badge-secondary">String</span>'
    html <<     '</th>'
    html <<     '<td>'
    if profile_element.data_type == MetadataProfileElement::DataType::MULTI_LINE_STRING
      html << text_area_tag("elements[#{profile_element.name}][#{vocabulary.id}][][string]",
                            element&.value,
                            id: "elements[#{profile_element.name}][#{vocabulary.id}][string]",
                            class: 'form-control',
                            autocomplete: 'off',
                            data: { controlled: 'false' })
    else
      html << text_field_tag("elements[#{profile_element.name}][#{vocabulary.id}][][string]",
                             element&.value,
                             id: "elements[#{profile_element.name}][#{vocabulary.id}][string]",
                             class: 'form-control',
                             autocomplete: 'off',
                             data: { controlled: 'true',
                                     'vocabulary-id': vocabulary.id })
    end
    html <<     '</td>'
    html <<     '<td style="width: 90px" rowspan="2">'
    html <<       '<div class="btn-group">'
    html <<         '<button class="btn btn-sm btn-light dl-add-element">'
    html <<           '<i class="fa fa-plus"></i>'
    html <<         '</button>'
    html <<         '<button class="btn btn-sm btn-danger dl-remove-element">'
    html <<           '<i class="fa fa-minus"></i>'
    html <<         '</button>'
    html <<       '</div>'
    html <<     '</td>'
    html <<   '</tr>'
    html <<   '<tr>'
    html <<     '<th style="text-align: right; width: 1px">'
    html <<       '<span class="badge badge-primary">URI</span>'
    html <<     '</th>'
    html <<     '<td>'
    html << text_field_tag("elements[#{profile_element.name}][#{vocabulary.id}][][uri]",
                           element&.uri,
                           id: "elements[#{profile_element.name}][#{vocabulary.id}][uri]",
                           class: 'form-control',
                           autocomplete: 'off',
                           data: { controlled: (vocabulary == Vocabulary.uncontrolled) ? 'false' : 'true',
                                   'vocabulary-id': vocabulary.id})
    html <<     '</td>'
    html <<   '</tr>'
    html << '</table>'
    raw(html.string)
  end

  ##
  # @param item [Item]
  # @return [String]
  #
  def admin_item_metadata_as_table(item)
    html = StringIO.new
    html << '<table class="table table-sm dl-metadata">'

    # Iterate through the index-ordered elements in the collection's metadata
    # profile in order to display the entity's elements in the correct order.
    defs = item.collection.effective_metadata_profile.elements
    defs.each do |e_def|
      elements = item.elements.
          select{ |e| e.name == e_def.name && (e.value.present? || e.uri.present?) }
      next if elements.empty?
      html << '<tr>'
      html <<   "<td>#{e_def.label}</td>"
      html <<   '<td>'
      html <<     '<table class="table table-sm">'
      elements.each do |element|
        if element.value.present?
          # Some URLs will be enclosed in angle brackets, which will foil
          # auto_link().
          haystack = element.value.gsub('<', '&lt; ').gsub('>', ' &gt;')
          value = auto_link(haystack, html: { target: '_blank' }).
              gsub('&lt; ', '&lt;').gsub(' &gt;', '&gt;')
          html << '<tr>'
          html <<   '<td style="width:1px"><span class="badge badge-secondary">String</span></td>'
          html <<   "<td>#{value}</td>"
          html << '</tr>'
        end
        if element.uri.present?
          html << '<tr>'
          html <<   '<td style="width:1px"><span class="badge badge-primary">URI</span></td>'
          html <<   "<td>#{element.uri}</td>"
          html << '</tr>'
        end
      end
      html <<     '</table>'
      html <<   '</td>'
      html << '</tr>'
    end
    html << '</table>'
    raw(html.string)
  end

  ##
  # Returns a series of Bootstrap media elements for the given [Item]s.
  #
  # @param items [Enumerable<Item>]
  # @return [String] HTML string.
  #
  def admin_items_as_media(items)
    html = StringIO.new
    html << '<ul class="list-unstyled">'
    items.each do |item|
      html << '<li class="media my-4">'

      # Checkboxes
      html << '<div class="dl-checkbox-container">'
      html <<   check_box_tag('dl-selected-items[]', item.repository_id)
      html << '</div>'

      # Thumbnail area
      html <<   '<div class="dl-thumbnail-container">'
      link_target = admin_collection_item_path(item.collection, item)
      html << link_to(link_target) do
        thumbnail_tag(item, shape: :square)
      end
      # N.B.: this was made by https://loading.io with the following settings:
      # rolling, color: #cacaca, radius: 25, stroke width: 10, speed: 5, size: 150
      html <<   image_tag('thumbnail-spinner.svg', class: 'dl-load-indicator')
      html << '</div>'

      html << '<div class="media-body">'

      # Title line
      html <<   '<h5 class="mt-0">'
      html <<     link_to(item.title, link_target)
      html <<   '</h5>'

      # Info line
      info_sections = []
      info_sections << "#{icon_for(item)} #{type_of(item)}"

      num_pages = item.pages.count
      if num_pages > 1
        page_count     = "#{num_pages} pages"
        three_d_item   = item.three_d_item
        page_count    += ' + 3D model' if three_d_item
        info_sections << page_count
      else
        num_files = item.items.where(variant: Item::Variants::FILE).count
        if num_files > 0
          info_sections << "#{num_files} files"
        else
          num_children = item.items.count
          if num_children > 0
            info_sections << "#{num_children} sub-items"
          end
        end
      end

      range = [
        item.respond_to?(:date) ? item.date : nil,
        item.respond_to?(:end_date) ? item.end_date : nil
      ]
      info_sections << range.select(&:present?).map(&:year).join('-') if range.any?

      if item.published
        info_sections << '<span class="text-success"><i class="fa fa-check"></i> Published</span>'
      else
        info_sections << '<span class="text-danger"><i class="fa fa-lock"></i> Unpublished</span>'
      end

      if item.expose_full_text_search
        info_sections << '<span class="text-success"><i class="fa fa-check"></i> Full Text Search Enabled</span>'
      else
        info_sections << '<span class="text-danger"><i class="fa fa-times"></i> Full Text Search Enabled</span>'
      end

      if item.ocred?
        info_sections << '<span class="text-success"><i class="fa fa-check"></i> OCR</span>'
      else
        info_sections << '<span class="text-danger"><i class="fa fa-times"></i> OCR</span>'
      end

      html << '<span class="dl-info-line">'
      html <<   info_sections.join('&nbsp;&nbsp;|&nbsp;&nbsp;')
      html << '</span>'
      html << '<span class="dl-description">'

      desc_e = item.collection.descriptive_element
      if desc_e
        description = item.element(desc_e.name)&.value
        if description.present?
          html << truncate(description, length: 380)
        end
      end

      html <<       '</span>'
      html <<     '</div>'
      html <<   '</li>'
    end
    html << '</ul>'
    raw(html.string)
  end

  ##
  # @param item [Item]
  # @param include_subitems [Boolean]
  # @param filenames_instead_of_titles [Boolean]
  #
  def admin_structure_of_item(item,
                              include_subitems: true,
                              filenames_instead_of_titles: false)
    # 1. Build the item structure excluding parents
    html = StringIO.new
    html << '<ul>'
    title = filenames_instead_of_titles ?
        (item.virtual_filename || item.title) : item.title
    html << "<li><strong>#{icon_for(item)} #{title}</strong>"
    if include_subitems
      subitems = item.search_children.
          include_unpublished(true).
          include_publicly_inaccessible(true).
          include_restricted(true)
      if subitems.any?
        html << '<ul>'
        subitems.each do |child|
          title = filenames_instead_of_titles ?
              (child.virtual_filename || child.title) : child.title
          html << '<li>'
          html << icon_for(child)
          html << ' '
          html << link_to(title,
                          admin_collection_item_path(child.collection, child))
          html << '</li>'
        end
        html << '</ul>'
      end
    end
    html <<   '</li>'
    html << '</ul>'

    # 2. Add the item context around the item tree
    def add_parents(item, html, filenames_instead_of_titles)
      parent = item.parent
      phtml = html
      if parent
        phtml = StringIO.new
        phtml << '<ul>'
        title = filenames_instead_of_titles ?
            (parent.virtual_filename || parent.title) : parent.title
        phtml <<   '<li>'
        phtml <<     icon_for(parent)
        phtml <<     ' '
        phtml <<     link_to(title, admin_collection_item_path(parent.collection, parent))
        phtml <<     html.string
        phtml <<   '</li>'
        phtml << '</ul>'
        phtml = add_parents(parent, phtml, filenames_instead_of_titles)
      end
      phtml
    end
    html = add_parents(item, html, filenames_instead_of_titles)

    raw(html.string)
  end

  def bootstrap_class_for_task_status(status)
    case status
      when ::Task::Status::SUCCEEDED
        'badge-success'
      when ::Task::Status::FAILED
        'badge-danger'
      when ::Task::Status::RUNNING
        'badge-primary'
      when ::Task::Status::PAUSED
        'badge-info'
      when ::Task::Status::WAITING
        'badge-default'
    end
  end

  def admin_system_info_as_list(item)
    html = StringIO.new
    html << '<dl class="d-block d-sm-none">'
    admin_system_info_data(item).each do |info|
      if info[:value].respond_to?(:each)
        info[:value] = "<ul>#{info[:value].map{ |v| "<li>#{v}</li>" }.join}</ul>"
      end
      html << "<dt>#{info[:label]}"
      if info[:help]
        html << " <a data-toggle=\"popover\" data-content=\"#{info[:help]}\">"\
            "<i class=\"fa fa-question-circle\"></i></a>"
      end
      html << "</dt>"
      html << "<dd>#{info[:value]}</dd>"
    end
    html << '</dl>'
    raw(html.string)
  end

  def admin_system_info_as_table(item)
    html = StringIO.new
    html << '<table class="table d-none d-sm-block">'
    admin_system_info_data(item).each do |info|
      if info[:value].respond_to?(:each)
        info[:value] = "<ul>#{info[:value].map{ |v| "<li>#{v}</li>" }.join}</ul>"
      end
      html << "<tr><td>#{info[:label]}"
      if info[:help]
        html << " <a data-toggle=\"popover\" data-content=\"#{info[:help]}\">"\
            "<i class=\"fa fa-question-circle\"></i></a>"
      end
      html << "</td><td>#{info[:value]}</td></tr>"
    end
    html << '</table>'
    raw(html.string)
  end

  def admin_item_structure_breadcrumb(item)
    html = StringIO.new
    parent = item.parent
    while parent
      html << '<li class="breadcrumb-item">'
      html <<   link_to(truncate(parent.title, length: 50),
                        admin_collection_item_path(parent.collection, parent))
      html << '</li>'
      html << html.string
      parent = parent.parent
    end
    if action_name == 'edit'
      value = link_to(truncate(item.title, length: 50),
                      admin_collection_item_path(item.collection, item))
    else
      value = truncate(item.title, length: 50)
    end
    html << '<li class="breadcrumb-item active">'
    html <<   value
    html << '</li>'
    html.string
  end

  ##
  # Returns pagination for collection results view.
  #
  # @param count [Integer]
  # @param per_page [Integer]
  # @param current_page [Integer]
  # @param max_links [Integer] (ideally odd)
  #
  def admin_paginate_collections(count, per_page, current_page, max_links = 9)
    do_paginate(count, per_page, current_page,
                params.permit(Admin::CollectionsController::PERMITTED_SEARCH_PARAMS),
                max_links)
  end


  private

  ##
  # @return [Array<Hash<Symbol,String>] Array of hashes with :label, :value,
  #                                     and :help keys.
  #
  def admin_system_info_data(item)
    data = []

    # Repository ID
    data << { label: 'Repository ID', value: "<code>#{item.repository_id}</code>" }

    # Database ID
    data << { label: 'Database ID', value: "<code>#{item.id}</code>" }

    # Binary filenames
    item.binaries.each do |bs|
      data << { label: "#{bs.human_readable_master_type} Filename",
                value: bs.filename}
    end

    # Variant
    data << { label: 'Variant', value: item.variant,
              help: "Available variants: #{Item::Variants::all.map{ |v| "<code>#{v}</code>" }.sort.join(', ')}" }

    # Page Number
    data << { label: 'Page Number', value: item.page_number }

    # Subpage Number
    data << { label: 'Subpage Number', value: item.subpage_number }

    # Normalized Start Date
    data << { label: 'Normalized Start Date', value: item.start_date }

    # Normalized End Date
    data << { label: 'Normalized End Date', value: item.end_date }

    # Normalized Longitude
    data << { label: 'Normalized Longitude', value: item.longitude }

    # Normalized Latitude
    data << { label: 'Normalized Latitude', value: item.latitude }

    # CONTENTdm Alias
    data << { label: 'CONTENTdm Alias', value: "<code>#{item.contentdm_alias}</code>" }

    # CONTENTdm Pointer
    data << { label: 'CONTENTdm Pointer', value: item.contentdm_pointer }

    # Rights Term (assigned)
    data << { label: "Rights Term (directly assigned)",
              help: "This term is assigned to an element that uses one of the rights-related vocabularies.",
              value: item.rights_term ?
                  link_to(item.rights_term.string,
                          item.rights_term.info_uri) : '' }
    # Rights Term (effective)
    data << { label: 'Rights Term (effective)',
              help: "This term is inherited from a parent item's rights-related "\
                    "element or the owning collection's rights term.",
              value: item.effective_rights_term ?
                  link_to(item.effective_rights_term.string,
                          item.effective_rights_term.info_uri) : '' }

    # Created
    data << { label: 'Created', value: local_time(item.created_at) }

    # First Published
    data << { label: 'First Published', value: item.published_at ? local_time(item.published_at) : nil }

    # Last Modified
    data << { label: 'Last Modified', value: local_time(item.updated_at) }

    data
  end

end
