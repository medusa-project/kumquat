module Admin

  class DashboardController < ControlPanelController

    def index
      @item_sets = current_user.item_sets.
          sort_by{ |s| "#{s.collection.title} #{s.name}" }
    end

  end

end
