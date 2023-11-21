# frozen_string_literal: true

module Admin

  class ItemPolicy < ApplicationPolicy

    def initialize(user, item)
      @user = user
      @item = item
    end

    def add_items_to_item_set?
      update?
    end

    def add_query_to_item_set?
      update?
    end

    def batch_change_metadata?
      update?
    end

    def edit_access?
      update?
    end

    def edit_all?
      update?
    end

    def edit_info?
      update?
    end

    def edit_metadata?
      update?
    end

    def edit_representation?
      update?
    end

    def enable_full_text_search?
      update?
    end

    def disable_full_text_search?
      update?
    end

    def import?
      update?
    end

    def index?
      show?
    end

    def migrate_metadata?
      update?
    end

    def publicize_child_binaries?
      update?
    end

    def publish?
      update?
    end

    def purge_cached_images?
      update?
    end

    def replace_metadata?
      update?
    end

    def run_ocr?
      update?
    end

    def show?
      update?
    end

    def sync?
      update?
    end

    def unpublicize_child_binaries?
      update?
    end

    def unpublish?
      update?
    end

    def update?
      @user.medusa_user?
    end

    def update_all?
      update?
    end

  end

end
