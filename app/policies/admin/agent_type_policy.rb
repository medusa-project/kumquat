# frozen_string_literal: true

module Admin

  class AgentTypePolicy < ApplicationPolicy

    def initialize(user, agent_type)
      @user       = user
      @agent_type = agent_type
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
