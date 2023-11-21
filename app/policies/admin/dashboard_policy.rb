# frozen_string_literal: true

module Admin

  class DashboardPolicy < ApplicationPolicy

    def initialize(user, ignored)
      @user = user
    end

    def index?
      @user.medusa_user?
    end

  end

end
