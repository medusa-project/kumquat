# frozen_string_literal: true

module Admin

  class ItemSetPolicy < ApplicationPolicy

    def initialize(user, item_set)
      @user     = user
      @item_set = item_set
    end

    def create?
      @user.medusa_user?
    end

    def destroy?
      update?
    end

    def edit?
      update?
    end

    def items?
      update?
    end

    def new?
      @user.medusa_user?
    end

    def remove_all_items?
      update?
    end

    def remove_items?
      update?
    end

    def show?
      update?
    end

    def update?
      @user.medusa_superuser? ||
        (@user.medusa_user? && @item_set.users.include?(@user))
    end

  end

end
