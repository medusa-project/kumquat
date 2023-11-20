# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy

  def initialize(user, collection)
    @user       = user
    @collection = collection
  end

  def delete_items?
    config = ::Configuration.instance
    if @user.medusa_superuser?
      return true
    elsif @user.medusa_admin?
      return config.medusa_admins_group[:permissions].include?(Permissions::PURGE_ITEMS_FROM_COLLECTION)
    elsif @user.medusa_user?
      return config.medusa_users_group[:permissions].include?(Permissions::PURGE_ITEMS_FROM_COLLECTION)
    end
    false
  end

  def edit_access?
    update?
  end

  def edit_info?
    update?
  end

  def edit_email_watchers?
    update?
  end

  def edit_representation?
    update?
  end

  def index?
    @user.medusa_user?
  end

  def items?
    index?
  end

  def purge_cached_images?
    update?
  end

  def show?
    update?
  end

  def statistics?
    show?
  end

  def sync?
    update?
  end

  def unwatch?
    watch?
  end

  def update?
    config = ::Configuration.instance
    if @user.medusa_superuser?
      return true
    elsif @user.medusa_admin?
      return config.medusa_admins_group[:permissions].include?(Permissions::MODIFY_COLLECTIONS)
    elsif @user.medusa_user?
      return config.medusa_users_group[:permissions].include?(Permissions::MODIFY_COLLECTIONS)
    end
    false
  end

  def watch?
    @user.medusa_user?
  end

end