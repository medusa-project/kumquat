module Admin

  class MetadataProfileElementsController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @element = MetadataProfileElement.new(sanitized_params)
      begin
        @element.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @element }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Element \"#{@element.label}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      element = MetadataProfileElement.find(params[:id])
      begin
        element.destroy!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Element \"#{element.label}\" deleted."
      ensure
        redirect_back fallback_location: admin_metadata_profiles_path
      end
    end

    ##
    # XHR only
    #
    def edit
      element = MetadataProfileElement.find(params[:id])
      profile = element.metadata_profile
      name_options_for_select = ItemElement.all_available.
          map{ |t| [ t.name, t.name ] }

      position_options_for_select = [['Nothing (First)', 0]]
      profile.elements.where('id != ?', element.id).order(:index).each_with_index do |e, i|
        position_options_for_select << [e.label, i + 1]
      end

      dublin_core_elements = DublinCoreElement.all.
          sort{ |e, f| e.label <=> f.label }.
          map { |p| [ p.label, p.name ] }
      dublin_core_terms = DublinCoreTerm.all.
          sort{ |e, f| e.label <=> f.label }.
          map { |p| [ p.label, p.name ] }
      render partial: 'admin/metadata_profile_elements/form',
             locals: { element: element,
                       metadata_profile: profile,
                       name_options_for_select: name_options_for_select,
                       position_options_for_select: position_options_for_select,
                       dublin_core_elements: dublin_core_elements,
                       dublin_core_terms: dublin_core_terms,
                       vocabularies: Vocabulary.order(:name),
                       context: :edit }
    end

    ##
    # XHR only
    #
    def update
      element = MetadataProfileElement.find(params[:id])
      begin
        element.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: element }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'update'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Element \"#{element.label}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_params
      params.require(:metadata_profile_element).permit(
          :dc_map, :dcterms_map, :facetable, :index, :label,
          :metadata_profile_id, :name, :searchable, :sortable,
          :visible, vocabulary_ids: [])
    end

  end

end
