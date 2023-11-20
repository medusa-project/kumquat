# frozen_string_literal: true

class HostGroupPolicy < ApplicationPolicy

  def initialize(user, host_group)
    @user       = user
    @host_group = host_group
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
    update?
  end

  def show?
    update?
  end

  def update?
    @user.medusa_admin?
  end

end