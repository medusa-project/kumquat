module Admin

  class ThemesController < ControlPanelController

    def create
      @theme = Theme.new(sanitized_params)
      begin
        @theme.save!
      rescue => e
        flash['error'] = "#{e}"
        render 'new'
      else
        flash['success'] = "Theme \"#{@theme.name}\" created."
        redirect_to admin_themes_url
      end
    end

    def destroy
      @theme = Theme.find(params[:id])
      begin
        @theme.destroy!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = "Theme \"#{@theme.name}\" deleted."
      ensure
        redirect_to admin_themes_url
      end
    end

    def edit
      @theme = Theme.find(params[:id])
    end

    def index
      @themes = Theme.order(:name)
    end

    def new
      @theme = Theme.new
    end

    def update
      @theme = Theme.find(params[:id])
      begin
        @theme.update(sanitized_params)
        @theme.save!
      rescue => e
        flash['error'] = "#{e}"
        render 'edit'
      else
        flash['success'] = "Theme \"#{@theme.name}\" updated."
        redirect_to admin_themes_url
      end
    end

    private

    def sanitized_params
      params.require(:theme).permit(:name, :default)
    end

  end

end
