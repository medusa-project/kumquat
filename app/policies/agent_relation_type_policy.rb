# frozen_string_literal: true

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
    update?
  end

  def new?
    create?
  end

  def update?
    @user.medusa_admin?
  end

end