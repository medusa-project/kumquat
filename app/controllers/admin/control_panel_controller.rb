module Admin

  class ControlPanelController < ApplicationController

    layout 'admin/application'

    before_action :authorize_user
    after_action :flash_in_response_headers

    protected

    ##
    # Normally the flash is discarded after being added to the response headers
    # (see flash_in_response_headers). Calling this method will save it,
    # enabling it to work with redirects. (Notably, it works different than
    # flash.keep.)
    #
    def keep_flash
      @keep_flash = true
    end

    private

    @keep_flash = false

    def authorize_user
      redirect_to signin_path unless current_user&.medusa_user?
    end

    ##
    # Stores the flash message and type ('error' or 'success') in the response
    # headers, where they can be accessed by an ajax callback. Afterwards, the
    # "normal" flash is cleared, which prevents it from working with redirects.
    # To prevent this, a controller should call keep_flash before redirecting.
    #
    def flash_in_response_headers
      if request.xhr?
        response.headers['X-Kumquat-Message-Type'] = 'error' unless
            flash['error'].blank?
        response.headers['X-Kumquat-Message-Type'] = 'success' unless
            flash['success'].blank?
        response.headers['X-Kumquat-Message'] = flash['error'] unless
            flash['error'].blank?
        response.headers['X-Kumquat-Message'] = flash['success'] unless
            flash['success'].blank?
        flash.clear unless @keep_flash
      end
    end

  end

end
