# frozen_string_literal: true

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
    config = ::Configuration.instance
    if @user.medusa_superuser?
      return true
    elsif @user.medusa_admin?
      return config.medusa_admins_group[:permissions].include?(Permissions::MODIFY_ELEMENTS)
    elsif @user.medusa_user?
      return config.medusa_users_group[:permissions].include?(Permissions::MODIFY_ELEMENTS)
    end
    false
  end

  def usages?
    show?
  end

end