# frozen_string_literal: true

module Admin

  class CollectionPolicy < ApplicationPolicy

    def initialize(user, collection)
      @user       = user
      @collection = collection
    end

    def delete_items?
      @user.medusa_admin?
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

    def export_permalinks_and_metadata?
      show?
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
      @user.medusa_user?
    end

    def watch?
      update?
    end

  end

end
