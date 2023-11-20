# frozen_string_literal: true

class AgentRelationPolicy < ApplicationPolicy

  def initialize(user, agent_relation)
    @user           = user
    @agent_relation = agent_relation
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

  def new?
    create?
  end

  def update?
    @user.medusa_admin?
  end

end