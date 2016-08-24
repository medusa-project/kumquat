module AdminHelper

  def admin_item_element_edit_tag(element_name, element_value)
    html = '<table class="table-condensed pt-element" style="width:100%">
      <tr>
        <td>'
    html += text_area_tag("elements[#{element_name}][]", element_value,
                          id: "elements[#{element_name}]",
                          class: 'form-control')
    html += '</td>
             <td style="width: 90px">
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
         </table>'
    raw(html)
  end

  ##
  # @param item [Item]
  #
  def admin_structure_of_item(item)
    # 1. Build the item structure excluding parents
    html = '<ul>'
    html += "  <li><strong>#{icon_for(item)} #{item.title}</strong>"
    if item.items.any?
      html += '  <ul>'
      item.items.each do |child|
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
    html += admin_item_structure_breadcrumb(item)
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
      html += "<dt>#{label}</dt><dd>#{value}</dd>"
    end
    html += '</dl>'
    raw(html)
  end

  def admin_system_info_as_table(item)
    html = '<table class="table hidden-xs">'
    admin_system_info_data(item).each do |label, value|
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

    iiif_url = iiif_item_url(item)
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

    if item.rightsstatements_org_statement
      data['RightsStatements.org'] =
          link_to(item.rightsstatements_org_statement.info_uri, target: '_blank') do
        image_tag(item.rightsstatements_org_statement.image,
                      alt: item.rightsstatements_org_statement.name)
      end
    end

    data['Rights Statement'] = item.rights_statement
    data['Created'] = local_time(item.created_at)
    data['Last Modified'] = local_time(item.updated_at)
    data
  end

end
