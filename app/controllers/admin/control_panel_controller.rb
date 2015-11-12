module Admin

  class ControlPanelController < ApplicationController

    layout 'admin/application'

    before_action :signed_in_user, :can_access_control_panel
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

    def can_access_control_panel
      #unless current_user.has_permission?(Permission::ACCESS_CONTROL_PANEL)
      #  flash['error'] = 'Access denied.'
      #  redirect_to root_url
      #end
    end

    ##
    # Stores the flash message and type ('error' or 'success') in the response
    # headers, where they can be accessed by an ajax callback. Afterwards, the
    # "normal" flash is cleared, which prevents it from working with redirects.
    # To prevent this, a controller should call keep_flash before redirecting.
    #
    def flash_in_response_headers
      if request.xhr?
        response.headers['X-PearTree-Message-Type'] = 'error' unless
            flash['error'].blank?
        response.headers['X-PearTree-Message-Type'] = 'success' unless
            flash['success'].blank?
        response.headers['X-PearTree-Message'] = flash['error'] unless
            flash['error'].blank?
        response.headers['X-PearTree-Message'] = flash['success'] unless
            flash['success'].blank?
        flash.clear unless @keep_flash
      end
    end

  end

end
