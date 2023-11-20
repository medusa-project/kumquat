# frozen_string_literal: true

module Admin

  class ControlPanelController < ApplicationController

    include Pundit::Authorization

    rescue_from Pundit::NotAuthorizedError, with: :rescue_unauthorized

    layout 'admin/application'

    before_action :authorize_current_user
    after_action :flash_in_response_headers


    private

    def authorize_current_user
      if !current_user
        redirect_to signin_path
      elsif !current_user.medusa_user?
        raise Pundit::NotAuthorizedError
      end
    end

    def rescue_unauthorized
      message = 'You are not authorized to access this page.'
      respond_to do |format|
        format.html do
          render 'errors/error', status: :forbidden, locals: {
            status_code:    403,
            status_message: 'Forbidden',
            message:        message
          }
        end
        format.json do
          render 'errors/error', status: :forbidden,
                 locals: { message: message }
        end
        format.all do
          render plain:        "403 Forbidden",
                 status:       :forbidden,
                 content_type: "text/plain"
        end
      end
    end

  end

end
