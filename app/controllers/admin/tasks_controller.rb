module Admin

  class TasksController < ControlPanelController

    ##
    # Responds to GET /admin/tasks
    #
    def index
      @tasks = Task.order(created_at: :desc).limit(100)

      render partial: 'tasks' if request.xhr?
    end

  end

end
