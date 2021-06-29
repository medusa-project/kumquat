module Admin

  class DashboardController < ControlPanelController

    ##
    # Responds to `GET /admin`
    #
    def index
      @item_sets = current_user.item_sets.
          sort_by{ |s| "#{s.collection.title} #{s.name}" }
      @watches = current_user.watches
    end

  end

end
