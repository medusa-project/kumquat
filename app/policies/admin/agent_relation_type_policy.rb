# frozen_string_literal: true

module Admin

  class AgentRelationTypePolicy < ApplicationPolicy

    def initialize(user, type)
      @user = user
      @type = type
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

    def index?
      @user.medusa_user?
    end

    def new?
      create?
    end

    def update?
      @user.medusa_admin?
    end

  end

end
