# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy

  def initialize(user, task)
    @user = user
    @task = task
  end

  def index?
    @user.medusa_user?
  end

  def show?
    @user.medusa_user?
  end

end