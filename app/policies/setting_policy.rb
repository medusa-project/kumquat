# frozen_string_literal: true

class SettingPolicy < ApplicationPolicy

  def initialize(user, ignored)
    @user = user
  end

  def index?
    update?
  end

  def update?
    config = ::Configuration.instance
    if @user.medusa_superuser?
      return true
    elsif @user.medusa_admin?
      return config.medusa_admins_group[:permissions].include?(Permissions::MODIFY_SETTINGS)
    elsif @user.medusa_user?
      return config.medusa_users_group[:permissions].include?(Permissions::MODIFY_SETTINGS)
    end
    false
  end

end