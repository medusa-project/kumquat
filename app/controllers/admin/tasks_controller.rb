# frozen_string_literal: true

module Admin

  class TasksController < ControlPanelController

    PERMITTED_SEARCH_PARAMS = [:q, :queue, :start, :status]

    ##
    # Responds to GET /admin/tasks
    #
    def index
      authorize(Task)
      @limit = Setting::integer(Setting::Keys::DEFAULT_RESULT_WINDOW)
      @start = params[:start] ? params[:start].to_i : 0
      @start = 0 if @start < 0

      @tasks = Task.order("started_at DESC NULLS FIRST")

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

      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 
      @count        = @tasks.count
      @tasks        = @tasks.offset(@start).limit(@limit)

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
      authorize(@task)
      render partial: 'show'
    end

  end

end
