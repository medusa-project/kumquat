module Admin

  class TasksController < ControlPanelController

    PERMITTED_PARAMS = [:q, :queue, :start, :status]

    ##
    # Responds to GET /admin/tasks
    #
    def index
      @limit = Option::integer(Option::Keys::DEFAULT_RESULT_WINDOW)
      @start = params[:start] ? params[:start].to_i : 0

      @tasks = Task.order(created_at: :desc)

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

      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
      @count = @tasks.count
      @tasks = @tasks.offset(@start).limit(@limit)

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
