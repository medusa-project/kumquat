module Admin

  class ControlPanelController < ApplicationController

    layout 'admin/application'

    before_action :authorize_user
    after_action :flash_in_response_headers


    private

    def authorize_user
      redirect_to signin_path unless current_user&.medusa_user?
    end

  end

end
