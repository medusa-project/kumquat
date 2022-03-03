module Admin

  class ControlPanelController < ApplicationController

    layout 'admin/application'

    before_action :authorize_user


    private

    def authorize_user
      redirect_to signin_path unless current_user&.medusa_user?
    end

  end

end
