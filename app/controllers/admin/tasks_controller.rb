module Admin

  class TasksController < ControlPanelController

    WINDOW = 90 # days

    ##
    # Responds to GET /admin/tasks
    #
    def index
      @tasks = Task.order(created_at: :desc).
          where('started_at >= ?', WINDOW.days.ago)

      if params[:q].present?
        @tasks = @tasks.where('LOWER(status_text) LIKE ?',
                              "%#{params[:q].downcase}%")
      end
      if params[:queue].present?
        @tasks = @tasks.where(queue: params[:queue])
      end
      if params[:status].present?
        @tasks = @tasks.where(status: params[:status])
      end

      respond_to do |format|
        format.js
        format.html
      end
    end

    ##
    # Responds to GET /admin/tasks/:id (XHR only)
    #
    def show
      @task = Task.find(params[:id])
      render partial: 'show'
    end

  end

end
