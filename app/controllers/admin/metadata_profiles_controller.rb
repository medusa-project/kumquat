module Admin

  class MetadataProfilesController < ControlPanelController

    ##
    # Responds to PATCH /admin/metadata-profiles/:id/clone
    #
    def clone
      profile = MetadataProfile.find(params[:metadata_profile_id])
      begin
        clone = profile.dup
        clone.save!
      rescue => e
        handle_error(e)
        redirect_to :back
      else
        flash['success'] = "Cloned #{profile.name} as \"#{clone.name}\"."
        redirect_to admin_metadata_profile_path(clone)
      end
    end

    def create
      @profile = MetadataProfile.new(sanitized_params)
      @profile.add_default_elements
      begin
        @profile.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @profile }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Metadata profile \"#{@profile.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    ##
    # Responds to POST /metadata-profiles/:id/delete-elements
    #
    def delete_elements
      if params[:elements]&.respond_to?(:each)
        count = params[:elements].length
        if count > 0
          ActiveRecord::Base.transaction do
            MetadataProfileElement.destroy_all(id: params[:elements])
          end
          flash['success'] = "Deleted #{count} element(s)."
        end
      else
        flash['error'] = 'No elements to delete (none checked).'
      end
      redirect_to :back
    end

    def destroy
      profile = MetadataProfile.find(params[:id])
      begin
        profile.destroy!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Metadata profile \"#{profile.name}\" deleted."
      ensure
        redirect_to admin_metadata_profiles_url
      end
    end

    ##
    # Responds to POST /admin/metadata-profiles/import
    #
    def import
      begin
        raise 'No profile specified.' if params[:metadata_profile].blank?

        json = params[:metadata_profile].read.force_encoding('UTF-8')
        profile = MetadataProfile.from_json(json)
        profile.save!
      rescue => e
        handle_error(e)
        redirect_to admin_metadata_profiles_path
      else
        flash['success'] = "Profile imported as #{profile.name}."
        redirect_to admin_metadata_profiles_path
      end
    end

    def index
      @profiles = MetadataProfile.order(:name)
      @new_profile = MetadataProfile.new
    end

    def show
      @profile = MetadataProfile.find(params[:id])

      respond_to do |format|
        format.html do
          @new_element = @profile.elements.build
          @element_options_for_select =
              @profile.elements.map{ |t| [ t.name, t.id ] }
          @name_options_for_select = ItemElement.all_descriptive.
              sort{ |e, f| e.name <=> f.name }.
              map{ |t| [ t.name, t.name ] }
          @dublin_core_elements = DublinCoreElement.all.
              sort{ |e, f| e.label <=> f.label }.
              map { |p| [ p.label, p.name ] }
          @dublin_core_terms = DublinCoreTerm.all.
              sort{ |e, f| e.label <=> f.label }.
              map { |p| [ p.label, p.name ] }
        end
        format.json do
          filename = "#{CGI.escape(@profile.name)}.json"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
          render text: JSON.pretty_generate(@profile.as_json)
        end
      end
    end

    def update
      @profile = MetadataProfile.find(params[:id])
      if request.xhr?
        begin
          @profile.update!(sanitized_params)
        rescue ActiveRecord::RecordInvalid
          response.headers['X-PearTree-Result'] = 'error'
          render partial: 'shared/validation_messages',
                 locals: { entity: @profile }
        rescue => e
          response.headers['X-PearTree-Result'] = 'error'
          handle_error(e)
          keep_flash
          render 'update'
        else
          response.headers['X-PearTree-Result'] = 'success'
          flash['success'] = "Metadata profile \"#{@profile.name}\" updated."
          keep_flash
          render 'update' # update.js.erb will reload the page
        end
      else
        begin
          @profile.update!(sanitized_params)
        rescue ActiveRecord::RecordInvalid
          response.headers['X-PearTree-Result'] = 'error'
          render 'show'
        rescue => e
          response.headers['X-PearTree-Result'] = 'error'
          handle_error(e)
          render 'show'
        else
          response.headers['X-PearTree-Result'] = 'success'
          flash['success'] = "Metadata profile \"#{@profile.name}\" updated."
          redirect_to :back
        end
      end
    end

    private

    def sanitized_params
      params.require(:metadata_profile).permit(:default,
                                               :default_sortable_element_id,
                                               :name)
    end

  end

end
