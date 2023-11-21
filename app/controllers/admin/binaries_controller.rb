# frozen_string_literal: true

module Admin

  class BinariesController < ControlPanelController

    before_action :set_binary
    before_action :authorize_binary

    ##
    # Responds to `GET /admin/binaries/:binary_id/edit-access` (XHR only)
    #
    def edit_access
      render partial: 'admin/binaries/edit_access'
    end

    ##
    # Responds to `PATCH /admin/binaries/:binary_id/run-ocr`
    #
    def run_ocr
      if @binary.ocrable?
        OcrBinaryJob.perform_later(binary:        @binary,
                                   language_code: params[:language],
                                   user:          current_user)
      else
        raise 'Only access master images and PDFs support OCR.'
      end
    rescue => e
      handle_error(e)
    else
      response.headers['X-Kumquat-Result'] = 'success'
      flash['success'] = 'Running OCR in the background. '\
          'This should take less than a minute.'
    ensure
      redirect_back fallback_location:
                      admin_collection_item_path(@binary.item.collection, @binary.item)
    end

    ##
    # Responds to `POST /admin/binaries/:id` (XHR only)
    #
    def update
      @binary.update!(permitted_params)
    rescue ActiveRecord::RecordInvalid
      response.headers['X-Kumquat-Result'] = 'error'
      render partial: 'shared/validation_messages',
             locals:  { entity: @binary }
    rescue => e
      handle_error(e)
    else
      response.headers['X-Kumquat-Result'] = 'success'
      flash['success'] = "Binary \"#{@binary.filename}\" updated."
    ensure
      keep_flash
      render 'admin/shared/reload'
    end


    private

    def authorize_binary
      @binary ? authorize(@binary) : skip_authorization
    end

    def permitted_params
      params.require(:binary).permit(:public)
    end

    def set_binary
      @binary = Binary.find_by_medusa_uuid(params[:id] || params[:binary_id])
      raise ActiveRecord::RecordNotFound unless @binary
    end

  end

end
