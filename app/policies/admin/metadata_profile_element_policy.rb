# frozen_string_literal: true

module Admin

  class MetadataProfileElementPolicy < ApplicationPolicy

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

    def new?
      create?
    end

    def update?
      @user.medusa_admin?
    end

  end

end
