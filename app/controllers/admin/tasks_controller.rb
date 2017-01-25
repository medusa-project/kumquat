module Admin

  class TasksController < ControlPanelController

    ##
    # Responds to GET /admin/tasks
    #
    def index
      @tasks = Task.order(created_at: :desc).limit(100)

      render partial: 'tasks' if request.xhr?
    end

    ##
    # Responds to GET /admin/tasks/:id
    #
    def show
      @task = Task.find(params[:id])
    end

  end

end
