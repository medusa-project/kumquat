# frozen_string_literal: true

module Admin

  class SettingPolicy < ApplicationPolicy

    def initialize(user, ignored)
      @user = user
    end

    def index?
      update?
    end

    def update?
      @user.medusa_superuser?
    end

  end

end
