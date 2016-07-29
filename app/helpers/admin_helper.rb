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

end
