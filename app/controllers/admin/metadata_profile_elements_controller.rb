# frozen_string_literal: true

module Admin

  class MetadataProfileElementsController < ControlPanelController

    before_action :set_element, except: :create
    before_action :authorize_element, except: :create

    ##
    # XHR only
    #
    def create
      @element = MetadataProfileElement.new(permitted_params)
      authorize(@element)
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
      @element.destroy!
    rescue => e
      handle_error(e)
    else
      flash['success'] = "Element \"#{@element.label}\" deleted."
    ensure
      redirect_back fallback_location: admin_metadata_profiles_path
    end

    ##
    # XHR only
    #
    def edit
      render partial: 'admin/metadata_profile_elements/form',
             locals: { element:          @element,
                       metadata_profile: @element.metadata_profile }
    end

    ##
    # XHR only
    #
    def update
      @element.update!(permitted_params)
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
      flash['success'] = "Element \"#{@element.label}\" updated."
      keep_flash
      render 'admin/shared/reload'
    end


    private

    def authorize_element
      @element ? authorize(@element) : skip_authorization
    end

    def permitted_params
      params.require(:metadata_profile_element).permit(
          :data_type, :dc_map, :dcterms_map, :facet_order, :facetable, :index,
          :indexed, :label, :metadata_profile_id, :name, :searchable,
          :sortable, :visible, vocabulary_ids: [])
    end

    def set_element
      @element = MetadataProfileElement.find(params[:id])
    end

  end

end
