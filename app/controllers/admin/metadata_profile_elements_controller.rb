module Admin

  class MetadataProfileElementsController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @element = MetadataProfileElement.new(sanitized_params)
      begin
        @element.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @element }
      rescue => e
        handle_error(e)
        keep_flash
        render 'admin/shared/reload'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Element \"#{@element.label}\" created."
        keep_flash
        render 'admin/shared/reload'
      end
    end

    def destroy
      element = MetadataProfileElement.find(params[:id])
      begin
        element.destroy!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Element \"#{element.label}\" deleted."
      ensure
        redirect_back fallback_location: admin_metadata_profiles_path
      end
    end

    ##
    # XHR only
    #
    def edit
      element = MetadataProfileElement.find(params[:id])
      profile = element.metadata_profile

      render partial: 'admin/metadata_profile_elements/form',
             locals: { element: element,
                       metadata_profile: profile }
    end

    ##
    # XHR only
    #
    def update
      element = MetadataProfileElement.find(params[:id])
      begin
        element.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: element }
      rescue => e
        handle_error(e)
        keep_flash
        render 'admin/shared/reload'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Element \"#{element.label}\" updated."
        keep_flash
        render 'admin/shared/reload'
      end
    end

    private

    def sanitized_params
      params.require(:metadata_profile_element).permit(
          :data_type, :dc_map, :dcterms_map, :facetable, :index, :indexed,
          :label, :metadata_profile_id, :name, :searchable, :sortable,
          :visible, vocabulary_ids: [])
    end

  end

end
