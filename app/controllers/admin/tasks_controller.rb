module Admin

  class TasksController < ControlPanelController

    ##
    # Responds to GET /admin/tasks
    #
    def index
      set_tasks_ivar
      @selected_id = params[:selected_id]&.to_i
      render partial: 'tasks' if request.xhr?
    end

    ##
    # Responds to GET /admin/tasks/:id
    #
    def show
      set_tasks_ivar
      @task = Task.find(params[:id])
      @selected_id = @task.id
    end

    private

    def set_tasks_ivar
      @tasks = Task.order(created_at: :desc).limit(100)
    end

  end

end
