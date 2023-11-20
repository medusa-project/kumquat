# frozen_string_literal: true

class VocabularyTermPolicy < ApplicationPolicy

  def initialize(user, term)
    @user = user
    @term = term
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

  def update?
    @user.medusa_admin?
  end

end