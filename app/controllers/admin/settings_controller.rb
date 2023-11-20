# frozen_string_literal: true

module Admin

  ##
  # To add a new setting:
  #
  # 1) Add it to {Option::Keys}
  # 2) Add it to seeds.rb if necessary
  # 3) Add it to `views/admin/settings/index.html`
  #
  class SettingsController < ControlPanelController

    def index
      authorize(Option)
    end

    ##
    # Responds to PATCH /admin/settings/update
    #
    def update
      authorize(Option)
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

  end

end
