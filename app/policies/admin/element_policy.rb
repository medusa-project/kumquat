# frozen_string_literal: true

module Admin

  class ElementPolicy < ApplicationPolicy

    def initialize(user, element)
      @user    = user
      @element = element
    end

    def create?
      update?
    end

    def destroy?
      update?
    end

    def edit?
      update?
    end

    def import?
      update?
    end

    def index?
      show?
    end

    def new?
      create?
    end

    def show?
      @user.medusa_user?
    end

    def update?
      @user.medusa_admin?
    end

    def usages?
      show?
    end

  end

end
