# frozen_string_literal: true

class BinaryPolicy < ApplicationPolicy

  def initialize(user, binary)
    @user   = user
    @binary = binary
  end

  def edit_access?
    update?
  end

  def run_ocr?
    @user.medusa_user?
  end

  def update?
    @user.medusa_admin?
  end

end