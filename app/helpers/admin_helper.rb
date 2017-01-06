module AdminHelper

  ##
  # @param collection [Collection]
  # @return [String]
  #
  def admin_collection_hierarchy(collection)
    child_html = ''
    if collection.children.count > 0
      child_html += '<ul>'
      collection.children.each do |child|
        child_html += "  <li>#{link_to(child.title, admin_collection_path(child))}</li>"
      end
      child_html += '</ul>'
    end

    parent_html = ''
    if collection.parents.count > 0
      collection.parents.each do |parent|
        parent_html += "  <li>#{link_to(parent.title, admin_collection_path(parent))}</li>"
      end
    end

    html = ''
    if parent_html.present?
      html += '<ul>'
      html += parent_html
      html += '<ul>'
      html += "  <li>#{collection.title}"
      html += child_html
      html += '  </li>'
      html += '</ul>'
    elsif child_html.present?
      html += '<ul>'
      html += "  <li>#{collection.title}"
      html += child_html
      html += '  </li>'
      html += '</ul>'
    end
    raw(html)
  end

  ##
  # @param profile_element [MetadataProfileElement]
  # @param element [ItemElement, nil]
  # @param vocabulary [Vocabulary]
  # @return [String]
  #
  def admin_item_element_edit_tag(profile_element, element, vocabulary)
    terms = vocabulary.vocabulary_terms.order(:string)

    html = '<table class="table-condensed pt-element" style="width:100%">
      <tr>
        <th style="text-align: right; width: 1px"><span class="label label-default">String</span></th>
        <td>'
    if vocabulary == Vocabulary.uncontrolled
      html += text_area_tag("elements[#{profile_element.name}][#{vocabulary.id}][][string]",
                            element&.value,
                            id: "elements[#{profile_element.name}][#{vocabulary.id}][string]",
                            class: 'form-control',
                            data: { controlled: 'false' })
    elsif terms.any?
      html += select_tag("elements[#{profile_element.name}][#{vocabulary.id}][][string]",
                         options_for_select(terms.map(&:string)),
                         id: "elements[#{profile_element.name}][#{vocabulary.id}][string]",
                         class: 'form-control',
                         data: { controlled: 'true',
                                 type: 'string',
                                 'vocabulary-id': vocabulary.id })
    else
      html += text_field_tag("elements[#{profile_element.name}][#{vocabulary.id}][][string]",
                             element&.value,
                             id: "elements[#{profile_element.name}][#{vocabulary.id}][string]",
                             class: 'form-control',
                             data: { controlled: 'true',
                                     'vocabulary-id': vocabulary.id })
    end
    html += '</td>
          <td style="width: 90px" rowspan="2">
            <div class="btn-group">
              <button class="btn btn-sm btn-default pt-add-element">
                <i class="fa fa-plus"></i>
              </button>
              <button class="btn btn-sm btn-danger pt-remove-element">
                <i class="fa fa-minus"></i>
              </button>
            </div>
          </td>
        </tr>
        <tr>
          <th style="text-align: right; width: 1px"><span class="label label-primary">URI</span></th>
          <td>'
    if vocabulary == Vocabulary.uncontrolled
      html += text_field_tag("elements[#{profile_element.name}][#{vocabulary.id}][][uri]",
                             element&.uri,
                             id: "elements[#{profile_element.name}][#{vocabulary.id}][uri]",
                             class: 'form-control',
                             data: { controlled: 'false',
                                     'vocabulary-id': vocabulary.id})
    elsif vocabulary.vocabulary_terms.any?
      html += select_tag("elements[#{profile_element.name}][#{vocabulary.id}][][uri]",
                         options_for_select(terms.map(&:uri)),
                         id: "elements[#{profile_element.name}][#{vocabulary.id}][uri]",
                         class: 'form-control',
                         data: { controlled: 'true',
                                 type: 'uri',
                                 'vocabulary-id': vocabulary.id })
    else
      html += text_field_tag("elements[#{profile_element.name}][#{vocabulary.id}][][uri]",
                             element&.uri,
                             id: "elements[#{profile_element.name}][#{vocabulary.id}][uri]",
                             class: 'form-control',
                             data: { controlled: 'true',
                                     'vocabulary-id': vocabulary.id})
    end
    html += '</td>
        </tr>
      </table>'
    raw(html)
  end

  ##
  # @param item [Item]
  # @return [String]
  #
  def admin_item_metadata_as_table(item)
    html = '<table class="table table-condensed pt-metadata">'

    # Iterate through the index-ordered elements in the collection's metadata
    # profile in order to display the entity's elements in the correct order.
    defs = item.collection.effective_metadata_profile.elements
    defs.each do |e_def|
      elements = item.elements.
          select{ |e| e.name == e_def.name and (e.value.present? or e.uri.present?) }
      next if elements.empty?
      html += '<tr>'
      html += "<td>#{e_def.label}</td>"
      html += '<td>'
      html += '<table class="table table-condensed">'
      elements.each do |element|
        if element.value.present?
          # Some URLs will be enclosed in angle brackets, which will foil
          # auto_link().
          haystack = element.value.gsub('<', '&lt; ').gsub('>', ' &gt;')
          value = auto_link(haystack, html: { target: '_blank' }).
              gsub('&lt; ', '&lt;').gsub(' &gt;', '&gt;')
          html += "<tr>"
          html += "<td style=\"width:1px\"><span class=\"label label-default\">String</span></td>"
          html += "<td>#{value}</td>"
          html += "</tr>"
        end
        if element.uri.present?
          html += "<tr>"
          html += "<td style=\"width:1px\"><span class=\"label label-primary\">URI</span></td>"
          html += "<td>#{element.uri}</td>"
          html += "</tr>"
        end
      end
      html += '</table>'
      html += '</td>'
      html += '</tr>'
    end
    html += '</table>'
    raw(html)
  end

  ##
  # @param item [Item]
  #
  def admin_structure_of_item(item)
    # 1. Build the item structure excluding parents
    html = '<ul>'
    html += "  <li><strong>#{icon_for(item)} #{item.title}</strong>"
    subitems = item.items_from_solr.
        order(Item::SolrFields::PAGE_NUMBER, Item::SolrFields::TITLE).
        limit(9999).to_a
    if subitems.any?
      html += '  <ul>'
      subitems.each do |child|
        link = link_to(child.title,
                       admin_collection_item_path(child.collection, child))
        html += "  <li>#{icon_for(child)} #{link}</li>"
      end
      html += '  </ul>'
    end
    html += '  </li>'
    html += '</ul>'

    # 2. Add the item context around the item tree
    def add_parents(item, html)
      parent = item.parent
      phtml = html
      if parent
        phtml = '<ul>'
        link = link_to(parent.title,
                       admin_collection_item_path(parent.collection, parent))
        phtml += "  <li>#{icon_for(parent)} #{link}"
        phtml +=      html
        phtml += '  </li>'
        phtml += '</ul>'
        phtml = add_parents(parent, phtml)
      end
      phtml
    end
    html = add_parents(item, html)

    # 3. Add the collection context around the items
    chtml = '<ul>'
    link = link_to(item.collection.title,
                   admin_collection_path(item.collection))
    chtml += "  <li>#{icon_for(item.collection)} #{link}"
    chtml +=      html
    chtml += '  </li>'
    chtml += '</ul>'

    raw(chtml)
  end

  def bootstrap_class_for_task_status(status)
    case status
      when ::Task::Status::SUCCEEDED
        'label-success'
      when ::Task::Status::FAILED
        'label-danger'
      when ::Task::Status::RUNNING
        'label-primary'
      when ::Task::Status::PAUSED
        'label-info'
      when ::Task::Status::WAITING
        'label-default'
    end
  end

  ##
  # @param options [Hash]
  # @option options [Collection] :collection
  # @option options [Item] :item
  # @return [String]
  #
  def admin_breadcrumb(options = {})
    case controller_name
      when 'collections'
        case action_name
          when 'index'
            return admin_collections_view_breadcrumb
          when 'show'
            return admin_collection_view_breadcrumb(options[:collection])
        end
      when 'items'
        case action_name
          when 'edit'
            return admin_item_edit_view_breadcrumb(options[:item])
          when 'edit_all'
            return admin_items_edit_view_breadcrumb(options[:collection])
          when 'index'
            return admin_results_breadcrumb(options[:collection])
          when 'show'
            return admin_item_view_breadcrumb(options[:item])
        end
    end
    nil
  end

  def admin_collection_view_breadcrumb(collection)
    html = "<ol class=\"breadcrumb\">"\
      "<li>#{link_to 'Home', admin_root_path}</li>"\
      "<li>#{link_to 'Collections', admin_collections_path}</li>"\
      "<li class=\"active\">#{truncate(collection.title, length: 50)}</li>"\
    "</ol>"
    raw(html)
  end

  def admin_collections_view_breadcrumb
    html = "<ol class=\"breadcrumb\">"\
      "<li>#{link_to 'Home', admin_root_path}</li>"\
      "<li class=\"active\">#{link_to 'Collections', admin_collections_path}</li>"\
    "</ol>"
    raw(html)
  end

  def admin_item_structure_breadcrumb(item)
    html = ''
    parent = item.parent
    while parent
      html = "<li>#{link_to truncate(parent.title, length: 50),
                            admin_collection_item_path(parent.collection, parent)}</li>#{html}"
      parent = parent.parent
    end
    if action_name == 'edit'
      value = link_to(truncate(item.title, length: 50),
                      admin_collection_item_path(item.collection, item));
    else
      value = truncate(item.title, length: 50)
    end
    html += "<li class=\"active\">#{value}</li>"
    html
  end

  def admin_item_edit_view_breadcrumb(item)
    html = "<ol class=\"breadcrumb\">"
    html += "<li>#{link_to 'Home', admin_root_path}</li>"
    html += "<li>#{link_to 'Collections', admin_collections_path}</li>"
    html += "<li>#{link_to item.collection.title, admin_collection_path(item.collection)}</li>"
    html += admin_item_structure_breadcrumb(item)
    html += "<li>Edit</li>"
    html += "</ol>"
    raw(html)
  end

  def admin_item_view_breadcrumb(item)
    html = "<ol class=\"breadcrumb\">"
    html += "<li>#{link_to 'Home', admin_root_path}</li>"
    html += "<li>#{link_to 'Collections', admin_collections_path}</li>"
    html += "<li>#{link_to item.collection.title, admin_collection_path(item.collection)}</li>"
    html += "<li>#{link_to 'Items', admin_collection_items_path(item.collection)}</li>"
    html += admin_item_structure_breadcrumb(item)
    html += "</ol>"
    raw(html)
  end

  def admin_items_edit_view_breadcrumb(collection)
    html = "<ol class=\"breadcrumb\">"
    html += "<li>#{link_to 'Home', admin_root_path}</li>"
    html += "<li>#{link_to 'Collections', admin_collections_path}</li>"
    html += "<li>#{link_to collection.title, admin_collection_path(collection)}</li>"
    html += "<li>#{link_to 'Items', admin_collection_items_path(collection)}</li>"
    html += "<li class=\"active\">Edit</li>"
    html += "</ol>"
    raw(html)
  end

  def admin_results_breadcrumb(collection)
    html = "<ol class=\"breadcrumb\">"\
      "<li>#{link_to('Home', admin_root_path)}</li>"\
      "<li>#{link_to('Collections', admin_collections_path)}</li>"\
      "<li>#{link_to(truncate(collection.title, length: 50), admin_collection_path(collection))}</li>"\
      "<li class=\"active\">Items</li>"\
    "</ol>"
    raw(html)
  end

  def admin_system_info_as_list(item)
    html = '<dl class="visible-xs hidden-sm">'
    admin_system_info_data(item).each do |label, value|
      if value.respond_to?(:each)
        value = "<ul>#{value.map{ |v| "<li>#{v}</li>" }.join}</ul>"
      end
      html += "<dt>#{label}</dt><dd>#{value}</dd>"
    end
    html += '</dl>'
    raw(html)
  end

  def admin_system_info_as_table(item)
    html = '<table class="table hidden-xs">'
    admin_system_info_data(item).each do |label, value|
      if value.respond_to?(:each)
        value = "<ul>#{value.map{ |v| "<li>#{v}</li>" }.join}</ul>"
      end
      html += "<tr><td>#{label}</td><td>#{value}</td></tr>"
    end
    html += '</table>'
    raw(html)
  end

  private

  def admin_system_info_data(item)
    data = {}
    data['Repository ID'] = item.repository_id
    data['Published'] = "<span class=\"label #{item.published ? 'label-success' : 'label-danger'}\">"\
        "#{item.published ? 'Published' : 'Unpublished' }</span>"

    iiif_url = item.iiif_url
    data['IIIF URL'] = iiif_url.present? ?
        link_to(iiif_url, iiif_url, target: '_blank') : 'None'

    data['Variant'] = item.variant

    data['Representative Item'] = item.representative_item ?
      link_to(item.representative_item.title,
                      admin_collection_item_path(item.representative_item.collection,
                                                 item.representative_item)) : ''
    data['Page Number'] = item.page_number
    data['Subpage Number'] = item.subpage_number
    data['Normalized Date'] = item.date
    data['Normalized Longitude'] = item.longitude
    data['Normalized Latitude'] = item.latitude
    data['CONTENTdm Alias'] = item.contentdm_alias
    data['CONTENTdm Pointer'] = item.contentdm_pointer
    data['RightsStatements.org (assigned)'] = item.rightsstatements_org_statement ?
        link_to(item.rightsstatements_org_statement.name,
                item.rightsstatements_org_statement.info_uri,
                target: '_blank') : ''
    data['RightsStatements.org (effective)'] = item.effective_rightsstatements_org_statement ?
        link_to(item.effective_rightsstatements_org_statement.name,
                item.effective_rightsstatements_org_statement.info_uri,
                target: '_blank') : ''

    data['Allowed Roles (assigned)'] = item.allowed_roles.any? ?
        item.allowed_roles.map(&:name) : 'Any'
    effective_allowed_roles = item.effective_allowed_roles
    data['Allowed Roles (effective)'] = effective_allowed_roles.any? ?
        effective_allowed_roles.map(&:name) : 'Any'
    data['Denied Roles (assigned)'] = item.denied_roles.any? ?
        item.denied_roles.map(&:name) : 'None'
    effective_denied_roles = item.effective_denied_roles
    data['Denied Roles (effective)'] = effective_denied_roles.any? ?
        effective_denied_roles.map(&:name) : 'None'

    data['Created'] = local_time(item.created_at)
    data['Last Modified'] = local_time(item.updated_at)
    data
  end

end
