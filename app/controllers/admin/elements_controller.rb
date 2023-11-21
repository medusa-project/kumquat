# frozen_string_literal: true

module Admin

  class ElementsController < ControlPanelController

    include ActionController::Live

    class ImportMode
      MERGE   = 'merge'
      REPLACE = 'replace'
    end

    before_action :set_element, except: [:create, :import, :index]
    before_action :authorize_element, except: [:create, :import, :index]

    ##
    # XHR only
    #
    def create
      @element = Element.new(permitted_params)
      authorize(@element)
      begin
        @element.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @element }
      rescue => e
        handle_error(e)
        keep_flash
        render 'admin/shared/reload'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Element \"#{@element.name}\" created."
        keep_flash
        render 'admin/shared/reload'
      end
    end

    def destroy
      @element.destroy!
    rescue => e
      handle_error(e)
    else
      flash['success'] = "Element \"#{@element.name}\" deleted."
    ensure
      redirect_back fallback_location: admin_elements_path
    end

    ##
    # XHR only
    #
    def edit
      render partial: 'admin/elements/form',
             locals: { element: @element }
    end

    ##
    # Responds to POST /admin/elements/import
    #
    def import
      authorize(Element)
      raise 'No elements specified.' if params[:elements].blank?
      json   = params[:elements].read.force_encoding('UTF-8')
      struct = JSON.parse(json)
      ActiveRecord::Base.transaction do
        if params[:import_mode] == ImportMode::REPLACE
          Element.delete_all # skip callbacks & validation
        end
        struct.each do |hash|
          e = Element.find_by_name(hash['name'])
          if e
            e.update_from_json_struct(hash)
          else
            Element.from_json_struct(hash).save!
          end
        end
      end
    rescue => e
      handle_error(e)
      redirect_to admin_elements_path
    else
      flash['success'] = "#{struct.length} elements created or updated."
      redirect_to admin_elements_path
    end

    ##
    # Responds to GET /elements
    #
    def index
      authorize(Element)
      respond_to do |format|
        format.html do
          sql = 'SELECT elements.id, elements.name, elements.description,
              (SELECT COUNT(metadata_profile_elements.name)
                FROM metadata_profile_elements
                WHERE metadata_profile_elements.name = elements.name) AS metadata_profile_count,
              (SELECT COUNT(entity_elements.name)
                FROM entity_elements
                WHERE entity_elements.name = elements.name) AS entity_count
              FROM elements
              GROUP BY elements.id, elements.name
              ORDER BY elements.name;'
          @elements    = ActiveRecord::Base.connection.exec_query(sql)
          @new_element = Element.new
        end
        format.json do
          @elements = Element.all.order(:name)
          headers['Content-Disposition'] = 'attachment; filename=elements.json'
          render plain: JSON.pretty_generate(@elements.as_json)
        end
      end
    end

    ##
    # Responds to GET /admin/elements/:name
    #
    def show
    end

    ##
    # XHR only
    #
    def update
      @element.update!(permitted_params)
    rescue ActiveRecord::RecordInvalid
      response.headers['X-Kumquat-Result'] = 'error'
      render partial: 'shared/validation_messages',
             locals:  { entity: @element }
    rescue => e
      handle_error(e)
      keep_flash
      render 'admin/shared/reload'
    else
      response.headers['X-Kumquat-Result'] = 'success'
      flash['success'] = "Element \"#{@element.name}\" updated."
      keep_flash
      render 'admin/shared/reload'
    end

    ##
    # Responds to GET /admin/elements/:name/usages with a TSV-format list of
    # all usages of a given element by all items.
    #
    def usages
      response.headers['Content-Type']        = 'text/tab-separated-values; charset=utf-8'
      response.headers['Content-Disposition'] = "attachment;filename=#{@element.name}.tsv"

      response.stream.write "collection_id\titem_id\telement_name\telement_value\telement_uri" +
                ItemTsvExporter::LINE_BREAK
      @element.usages.each do |row|
        response.stream.write row.values.join("\t")
        response.stream.write ItemTsvExporter::LINE_BREAK
      end
    ensure
      response.stream.close
    end


    private

    def authorize_element
      @element ? authorize(@element) : skip_authorization
    end

    def permitted_params
      params.require(:element).permit(:description, :name)
    end

    def set_element
      @element = Element.find_by_name(params[:name] || params[:element_name])
      raise ActiveRecord::RecordNotFound unless @element
    end

  end

end
