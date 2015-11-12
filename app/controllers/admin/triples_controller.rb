module Admin

  class TriplesController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @triple = Triple.new(sanitized_params)
      begin
        @triple.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @triple }
      rescue => e
        response.headers['X-Kumquat-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'create'
      else
        response.headers['X-Psap-Result'] = 'success'
        flash['success'] = "Triple \"#{@triple.label}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      triple = Triple.find(params[:id])
      begin
        triple.destroy!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = "Triple \"#{triple.label}\" deleted."
      ensure
        redirect_to :back
      end
    end

    ##
    # XHR only
    #
    def edit
      triple = Triple.find(params[:id])
      profile = triple.metadata_profile
      render partial: 'admin/triples/form',
             locals: { triple: triple, profile: profile, context: :edit }
    end

    ##
    # XHR only
    #
    def update
      triple = Triple.find(params[:id])
      begin
        triple.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: triple }
      rescue => e
        response.headers['X-Kumquat-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'update'
      else
        response.headers['X-Psap-Result'] = 'success'
        flash['success'] = "Triple \"#{triple.label}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_params
      params.require(:triple).permit(:facet_id, :facet_label, :index, :label,
                                     :metadata_profile_id, :predicate,
                                     :searchable, :visible)
    end

  end

end
