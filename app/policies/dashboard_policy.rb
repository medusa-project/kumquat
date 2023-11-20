# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy

  def initialize(user, ignored)
    @user = user
  end

  def index?
    @user.medusa_user?
  end

end
