module Admin

  ##
  # To add a new setting:
  #
  # 1) Add it to Option::Keys
  # 2) Add it to seeds.rb if necessary
  # 3) Add it to views/admin/settings/index.html.erb
  #
  class SettingsController < ControlPanelController

    def index
    end

    ##
    # Responds to PATCH /admin/settings/update
    #
    def update
      begin
        ActiveRecord::Base.transaction do
          params[:options].each_key do |key|
            option = Option.find_by_key(key)
            if option # if the option already exists
              if option.value != params[:options][key] # if the option has a new value
                option.value = params[:options][key]
                option.save!
              end
            else # it doesn't exist, so create it
              option = Option.new(key: key, value: params[:options][key])
              option.save!
            end
          end
        end
      rescue => e
        handle_error(e)
        render :index
      else
        flash['success'] = 'Settings updated.'
        redirect_to :back
      end
    end

  end

end
