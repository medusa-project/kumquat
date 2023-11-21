# frozen_string_literal: true

module Admin

  class AgentPolicy < ApplicationPolicy

    def initialize(user, agent)
      @user  = user
      @agent = agent
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

  end

end
