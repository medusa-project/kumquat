# frozen_string_literal: true

module Admin 

  class ItemEventPolicy < ApplicationPolicy
    
    def initialize(user, item_event)
      @user = user
      @item_event = item_event
    end

    def index?
      show?
    end

    def show?
      @user.medusa_user?
    end
  end

end