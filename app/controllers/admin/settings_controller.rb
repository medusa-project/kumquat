module Admin

  ##
  # To add a new setting:
  #
  # 1) Add it to Option::Keys
  # 2) Add it to seeds.rb if necessary
  # 3) Add it to views/admin/settings/index.html.erb
  #
  class SettingsController < ControlPanelController

    before_action :modify_settings_rbac, only: [:index, :update]

    def index
      @status_options = [[ 'Online', 'online' ],
                         [ 'Storage Offline', 'storage_offline']]
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
        redirect_back fallback_location: admin_settings_path
      end
    end

    private

    def modify_settings_rbac
      unless current_user.can?(Permission::Permissions::MODIFY_SETTINGS)
        flash['error'] = 'You do not have permission to perform this action.'
        redirect_to(admin_root_url)
      end
    end

  end

end
