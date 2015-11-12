module Admin

  class MetadataProfilesController < ControlPanelController

    ##
    # Responds to PATCH /admin/metadata-profiles/:id/clone
    #
    def clone
      profile = MetadataProfile.find(params[:metadata_profile_id])
      begin
        clone = profile.dup
        clone.name = ('Clone of ' + clone.name)[0..[clone.class.max_length(:name).to_i, 99999].max - 1]
        clone.save!
      rescue => e
        flash['error'] = "#{e}"
        redirect_to :back
      else
        flash['success'] = "Cloned #{profile.name} as \"#{clone.name}\"."
        redirect_to admin_metadata_profile_path(clone)
      end
    end

    def create
      @profile = MetadataProfile.new(sanitized_params)
      begin
        @profile.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @profile }
      rescue => e
        response.headers['X-Kumquat-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'create'
      else
        response.headers['X-Psap-Result'] = 'success'
        flash['success'] = "Metadata profile \"#{@profile.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      profile = MetadataProfile.find(params[:id])
      begin
        profile.destroy!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = "Metadata profile \"#{profile.name}\" deleted."
      ensure
        redirect_to admin_metadata_profiles_url
      end
    end

    def index
      @profiles = MetadataProfile.order(:name)
      @new_profile = MetadataProfile.new
    end

    def show
      @profile = MetadataProfile.find(params[:id])
      @new_triple = @profile.triples.build
    end

    def update
      @profile = MetadataProfile.find(params[:id])
      if request.xhr?
        begin
          @profile.update!(sanitized_params)
        rescue ActiveRecord::RecordInvalid
          response.headers['X-Kumquat-Result'] = 'error'
          render partial: 'shared/validation_messages',
                 locals: { entity: @profile }
        rescue => e
          response.headers['X-Kumquat-Result'] = 'error'
          flash['error'] = "#{e}"
          keep_flash
          render 'update'
        else
          response.headers['X-Psap-Result'] = 'success'
          flash['success'] = "Metadata profile \"#{@profile.name}\" updated."
          keep_flash
          render 'update' # update.js.erb will reload the page
        end
      else
        begin
          @profile.update!(sanitized_params)
        rescue ActiveRecord::RecordInvalid
          response.headers['X-Kumquat-Result'] = 'error'
          render 'show'
        rescue => e
          response.headers['X-Kumquat-Result'] = 'error'
          flash['error'] = "#{e}"
          render 'show'
        else
          response.headers['X-Psap-Result'] = 'success'
          flash['success'] = "Metadata profile \"#{@profile.name}\" updated."
          redirect_to :back
        end
      end
    end

    private

    def sanitized_params
      params.require(:metadata_profile).permit(:default, :name)
    end

  end

end
