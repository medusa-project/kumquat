# frozen_string_literal: true

module Admin

  class UserPolicy < ApplicationPolicy

    def initialize(subject_user, object_user)
      @subject_user = subject_user
      @object_user  = object_user
    end

    def create?
      config = ::Configuration.instance
      if @subject_user.medusa_superuser?
        return true
      elsif @subject_user.medusa_admin?
        return config.medusa_admins_group[:permissions].include?(Permissions::MODIFY_USERS)
      elsif @subject_user.medusa_user?
        return config.medusa_users_group[:permissions].include?(Permissions::MODIFY_USERS)
      end
      false
    end

    def destroy?
      create?
    end

    def index?
      config = ::Configuration.instance
      if @subject_user.medusa_superuser?
        return true
      elsif @subject_user.medusa_admin?
        return config.medusa_admins_group[:permissions].include?(Permissions::VIEW_USERS)
      elsif @subject_user.medusa_user?
        return config.medusa_users_group[:permissions].include?(Permissions::VIEW_USERS)
      end
      false
    end

    def new?
      create?
    end

    def reset_api_key?
      show?
    end

    def show?
      config = ::Configuration.instance
      if @subject_user.medusa_superuser? ||
        (@subject_user.medusa_user? && @subject_user == @object_user)
        return true
      elsif @subject_user.medusa_admin?
        return config.medusa_admins_group[:permissions].include?(Permissions::VIEW_USERS)
      elsif @subject_user.medusa_user?
        return config.medusa_users_group[:permissions].include?(Permissions::VIEW_USERS)
      end
      false
    end

  end

end
