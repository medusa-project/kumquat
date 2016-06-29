module Admin

  class AvailableElementsController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @element = AvailableElement.new(sanitized_params)
      begin
        @element.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @element }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Element \"#{@element.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      element = AvailableElement.find(params[:id])
      begin
        element.destroy!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = "Element \"#{element.name}\" deleted."
      ensure
        redirect_to :back
      end
    end

    ##
    # XHR only
    #
    def edit
      element = AvailableElement.find(params[:id])
      render partial: 'admin/available_elements/form',
             locals: { element: element, context: :edit }
    end

    ##
    # Responds to GET /elements
    def index
      @elements = AvailableElement.all.order(:name)
      @new_element = AvailableElement.new
    end

    ##
    # Responds to GET /elements/schema
    #
    def schema
      render 'schema.xml.builder'
    end

    ##
    # XHR only
    #
    def update
      element = AvailableElement.find(params[:id])
      begin
        element.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: element }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'update'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Element \"#{element.name}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_params
      params.require(:available_element).permit(:description, :name)
    end

  end

end
