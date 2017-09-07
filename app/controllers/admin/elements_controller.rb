module Admin

  class ElementsController < ControlPanelController

    class ImportMode
      MERGE = 'merge'
      REPLACE = 'replace'
    end

    PERMITTED_PARAMS = [:description, :name]

    before_action :set_permitted_params

    ##
    # XHR only
    #
    def create
      @element = Element.new(sanitized_params)
      begin
        @element.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @element }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
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
      element = Element.find(params[:id])
      begin
        element.destroy!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Element \"#{element.name}\" deleted."
      ensure
        redirect_back fallback_location: admin_elements_path
      end
    end

    ##
    # XHR only
    #
    def edit
      element = Element.find(params[:id])
      render partial: 'admin/elements/form',
             locals: { element: element, context: :edit }
    end

    ##
    # Responds to POST /admin/elements/import
    #
    def import
      begin
        raise 'No elements specified.' if params[:elements].blank?

        json = params[:elements].read.force_encoding('UTF-8')
        struct = JSON.parse(json)
        ActiveRecord::Base.transaction do
          if params[:import_mode] == ImportMode::REPLACE
            Element.delete_all # skip callbacks & validation
          end
          struct.each do |hash|
            e = Element.find_by_name(hash['name'])
            if e
              e.update_from_json_struct(hash)
            else
              Element.from_json_struct(hash).save!
            end
          end
        end
      rescue => e
        handle_error(e)
        redirect_to admin_elements_path
      else
        flash['success'] = "#{struct.length} elements created or updated."
        redirect_to admin_elements_path
      end
    end

    ##
    # Responds to GET /elements
    #
    def index
      respond_to do |format|
        format.html do
          sql = 'SELECT elements.id, elements.name, elements.description,
              COUNT(entity_elements.name) AS count
            FROM elements
            LEft JOIN entity_elements ON entity_elements.name = elements.name
            GROUP BY elements.id, elements.name
            ORDER BY elements.name'
          @elements = ActiveRecord::Base.connection.exec_query(sql)
          @new_element = Element.new
        end
        format.json do
          @elements = Element.all.order(:name)
          headers['Content-Disposition'] = 'attachment; filename=elements.json'
          render plain: JSON.pretty_generate(@elements.as_json)
        end
      end
    end

    ##
    # XHR only
    #
    def update
      element = Element.find(params[:id])
      begin
        element.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: element }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
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
      params.require(:element).permit(PERMITTED_PARAMS)
    end

    def set_permitted_params
      @permitted_params = params.permit(PERMITTED_PARAMS)
    end

  end

end
