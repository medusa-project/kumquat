# frozen_string_literal: true

module Admin

  class AgentRulePolicy < ApplicationPolicy

    def initialize(user, agent_rule)
      @user       = user
      @agent_rule = agent_rule
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
      update?
    end

    def new?
      create?
    end

    def update?
      @user.medusa_admin?
    end

  end

end
