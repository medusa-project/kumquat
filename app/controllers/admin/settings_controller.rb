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

    ##
    # Responds to PATCH /admin/settings/update
    #
    def update
      begin
        ActiveRecord::Base.transaction do
          params[:options].to_unsafe_hash.each_key do |key|
            Option.set(key, params[:options][key])
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
      unless current_user.can?(Permissions::MODIFY_SETTINGS)
        flash['error'] = 'You do not have permission to perform this action.'
        redirect_to(admin_root_url)
      end
    end

  end

end
