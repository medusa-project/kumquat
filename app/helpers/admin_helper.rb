module AdminHelper

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
