# frozen_string_literal: true

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
    update?
  end

  def new?
    create?
  end

  def show?
    update?
  end

  def update?
    @user.medusa_admin?
  end

end