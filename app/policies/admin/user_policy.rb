# frozen_string_literal: true

module Admin

  class UserPolicy < ApplicationPolicy

    def initialize(subject_user, object_user)
      @subject_user = subject_user
      @object_user  = object_user
    end

    def create?
      @subject_user.medusa_superuser?
    end

    def destroy?
      create?
    end

    def index?
      @subject_user.medusa_superuser?
    end

    def new?
      create?
    end

    def reset_api_key?
      show?
    end

    def show?
      @subject_user.medusa_superuser? ||
        (@subject_user.medusa_user? && @subject_user == @object_user)
    end

  end

end
