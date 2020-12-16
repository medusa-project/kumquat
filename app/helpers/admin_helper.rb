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
          select{ |e| e.name == e_def.name and (e.value.present? or e.uri.present?) }
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
  # @param item [Item]
  # @param options [Hash]
  # @option options [Boolean] :include_subitems
  # @option options [Boolean] :filenames_instead_of_titles
  #
  def admin_structure_of_item(item, options = {})
    include_subitems = options.keys.include?(:include_subitems) ?
        options[:include_subitems] : true
    filenames_instead_of_titles = options.keys.include?(:filenames_instead_of_titles) ?
        options[:filenames_instead_of_titles] : false

    # 1. Build the item structure excluding parents
    html = StringIO.new
    html << '<ul>'
    title = filenames_instead_of_titles ?
        (item.virtual_filename || item.title) : item.title
    html << "<li><strong>#{icon_for(item)} #{title}</strong>"
    if include_subitems
      subitems = item.search_children.
          include_unpublished(true).
          include_restricted(true).
          to_a
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
                params.permit(Admin::CollectionsController::PERMITTED_PARAMS),
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

    # Published
    data << { label: 'Published',
              value: "<span class=\"badge #{item.published ? 'badge-success' : 'badge-danger'}\">"\
                  "#{item.published ? 'Published' : 'Unpublished' }</span>"}

    # Primary IIIF Image URL
    iiif_url = item.effective_image_binary&.iiif_image_url
    data << { label: 'Primary IIIF Image URL',
              value: iiif_url.present? ?
                  link_to(iiif_url, iiif_url, target: '_blank') : 'None' }

    # Variant
    data << { label: 'Variant', value: item.variant,
              help: "Available variants are: #{Item::Variants::all.map{ |v| "<code>#{v}</code>" }.sort.join(' ')}" }

    # Representative Item
    data << { label: 'Representative Item',
              value: item.representative_item ?
                  link_to(item.representative_item.title,
                          admin_collection_item_path(item.representative_item.collection,
                                                     item.representative_item)) : '' }
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

    # RightsStatements.org (assigned)
    data << { label: 'RightsStatements.org (directly assigned)',
              value: item.rightsstatements_org_statement ?
                  link_to(item.rightsstatements_org_statement.name,
                          item.rightsstatements_org_statement.info_uri) : '' }
    # RightsStatements.org (effective)
    data << { label: 'RightsStatements.org (effective)',
              value: item.effective_rightsstatements_org_statement ?
                  link_to(item.effective_rightsstatements_org_statement.name,
                          item.effective_rightsstatements_org_statement.info_uri) : '' }

    # Allowed NetIDs
    netid_table = ''
    if item.allowed_netids&.any?
      netid_table = "<table class=\"table table-sm\">"
      netid_table += "<tr><th>NetID</th><th>Expires</th></tr>"
      item.allowed_netids.each do |h|
        expires = Time.at(h[:expires].to_i)
        netid_table += "<tr><td>#{h[:netid]}</td><td class=\"#{expires < Time.now ? "text-danger" : ""}\">#{local_time_ago(expires)}</td></tr>"
      end
      netid_table += "</table>"
    end
    data << { label: 'Allowed NetIDs', value: netid_table }
    if item.allowed_netids&.any?
      data << { label: 'Restricted URL',
                value: "#{item_url(item)} <button class=\"btn btn-light btn-sm dl-copy-to-clipboard\" data-clipboard-text=\"#{item_url(item)}\" type=\"button\"><i class=\"fa fa-clipboard\"></i></button>" }
    end

    # Allowed Host Groups (assigned)
    data << { label: 'Allowed Host Groups (directly assigned)',
              value: item.allowed_host_groups.any? ?
                  item.allowed_host_groups.map{ |g| link_to(g.name, admin_host_group_path(g)) } :
                         'Any' }
    # Allowed Host Groups (effective)
    effective_allowed_host_groups = item.effective_allowed_host_groups
    data << { label: 'Allowed Host Groups (effective)',
              value: effective_allowed_host_groups.any? ?
                  effective_allowed_host_groups.map{ |g| link_to(g.name, admin_host_group_path(g)) } :
                         'Any' }
    # Denied Host Groups (assigned)
    data << { label: 'Denied Host Groups (directly assigned)',
              value: item.denied_host_groups.any? ?
                  item.denied_host_groups.map{ |g| link_to(g.name, admin_host_group_path(g)) } :
                         'None' }
    # Denied Host Groups (effective)
    effective_denied_host_groups = item.effective_denied_host_groups
    data << { label: 'Denied Host Groups (effective)',
              value: effective_denied_host_groups.any? ?
                  effective_denied_host_groups.map{ |g| link_to(g.name, admin_host_group_path(g)) } :
                         'None' }
    # Created
    data << { label: 'Created', value: local_time(item.created_at) }

    # Last Modified
    data << { label: 'Last Modified', value: local_time(item.updated_at) }

    data
  end

end
