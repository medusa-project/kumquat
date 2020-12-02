module Admin

  class BinariesController < ControlPanelController

    before_action :set_binary

    ##
    # Responds to `GET /admin/binaries/:id/edit` (XHR only)
    #
    def edit
      render partial: 'admin/binaries/edit'
    end

    ##
    # Responds to `POST /admin/binaries/:id` (XHR only)
    #
    def update
      begin
        @binary.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @binary }
      rescue => e
        handle_error(e)
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Binary \"#{@binary.filename}\" updated."
      ensure
        keep_flash
        render 'admin/shared/reload'
      end
    end

    private

    def sanitized_params
      params.require(:binary).permit(:public)
    end

    def set_binary
      @binary = Binary.find_by_medusa_uuid(params[:id])
    end

  end

end
