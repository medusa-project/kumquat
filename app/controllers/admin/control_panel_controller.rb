# frozen_string_literal: true

module Admin

  class ControlPanelController < ApplicationController

    layout 'admin/application'

    before_action :ensure_logged_in
    after_action :flash_in_response_headers

    ##
    # Overrides parent.
    #
    # @param entity [Class] Model or any other object to which access can be
    #               authorized.
    # @param policy_class [ApplicationPolicy] Alternative policy class to use.
    # @param policy_method [Symbol] Alternative policy method to use.
    # @raises [NotAuthorizedError]
    #
    def authorize(entity, policy_class: nil, policy_method: nil)
      class_name     = controller_path.split("/").map(&:singularize).map(&:camelize).join("::")
      policy_class ||= "#{class_name}Policy".constantize
      instance       = policy_class.new(current_user, entity)
      result         = instance.send(policy_method&.to_sym || "#{action_name}?".to_sym)
      raise NotAuthorizedError.new unless result
    end

    def ensure_logged_in
      if !current_user
        redirect_to signin_path
      elsif !current_user.medusa_user?
        raise NotAuthorizedError
      end
    end

  end

end
