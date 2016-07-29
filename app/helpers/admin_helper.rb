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
