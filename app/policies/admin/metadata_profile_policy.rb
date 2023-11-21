# frozen_string_literal: true

module Admin

  class MetadataProfilePolicy < ApplicationPolicy

    def initialize(user, metadata_profile)
      @user             = user
      @metadata_profile = metadata_profile
    end

    def clone?
      update?
    end

    def create?
      update?
    end

    def delete_elements?
      update?
    end

    def destroy?
      update?
    end

    def edit?
      update?
    end

    def import?
      update?
    end

    def index?
      update?
    end

    def new?
      create?
    end

    def reindex_items?
      update?
    end

    def show?
      update?
    end

    def update?
      @user.medusa_admin?
    end

  end

end
