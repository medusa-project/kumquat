module Admin

  class FacetDefsController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @facet = FacetDef.new(sanitized_params)
      begin
        @facet.save!
        Solr.instance.update_schema
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @facet }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Facet \"#{@facet.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      facet = FacetDef.find(params[:id])
      begin
        facet.destroy!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = 'Facet deleted.'
      ensure
        redirect_to :back
      end
    end

    def index
      @facets = FacetDef.all.order(:name)
      @new_facet = FacetDef.new
    end

    ##
    # XHR only
    #
    def update
      facet = FacetDef.find(params[:id])
      begin
        facet.update!(sanitized_params)
        Solr.instance.update_schema
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: facet }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'update'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Facet \"#{facet.name}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_params
      params.require(:facet_def).permit(:index, :name, :solr_field)
    end

  end

end
