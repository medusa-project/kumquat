module Admin

  class ElementDefsController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @element = ElementDef.new(sanitized_params)
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
        flash['success'] = "Element \"#{@element.label}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      element = ElementDef.find(params[:id])
      begin
        element.destroy!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = "Element \"#{element.label}\" deleted."
      ensure
        redirect_to :back
      end
    end

    ##
    # XHR only
    #
    def edit
      element = ElementDef.find(params[:id])
      profile = element.metadata_profile
      name_options_for_select = ElementDef.all_available.
          select{ |ed| ed.type == Element::Type::DESCRIPTIVE }.
          map{ |t| [ t.name, t.name ] }
      render partial: 'admin/element_defs/form',
             locals: { element_def: element,
                       metadata_profile: profile,
                       name_options_for_select: name_options_for_select,
                       context: :edit }
    end

    ##
    # XHR only
    #
    def update
      element = ElementDef.find(params[:id])
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
        flash['success'] = "Element \"#{element.label}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_params
      params.require(:element_def).permit(:dc_map, :dcterms_map, :facetable,
                                          :index, :label, :metadata_profile_id,
                                          :name, :searchable, :sortable,
                                          :visible)
    end

  end

end
