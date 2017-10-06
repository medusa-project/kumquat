module Admin

  class VocabulariesController < ControlPanelController

    PERMITTED_PARAMS = [:key, :name]

    before_action :set_permitted_params

    def create
      @vocabulary = Vocabulary.new(sanitized_params)
      begin
        @vocabulary.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @vocabulary }
      rescue => e
        handle_error(e)
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Vocabulary \"#{@vocabulary.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    ##
    # Responds to POST /vocabularies/:id/delete-vocabulary-terms
    #
    def delete_vocabulary_terms
      vocab = Vocabulary.find(params[:vocabulary_id])
      if params[:vocabulary_terms]&.respond_to?(:each)
        count = params[:vocabulary_terms].length
        if count > 0
          ActiveRecord::Base.transaction do
            vocab.vocabulary_terms.where(id: params[:vocabulary_terms]).destroy_all
          end
          flash['success'] = "Deleted #{count} vocabulary term(s)."
        end
      else
        flash['error'] = 'No vocabulary terms to delete (none checked).'
      end
      redirect_back fallback_location: admin_vocabulary_path(vocab)
    end

    def destroy
      vocabulary = Vocabulary.find(params[:id])
      begin
        vocabulary.destroy!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Vocabulary \"#{vocabulary.name}\" deleted."
      ensure
        redirect_to admin_vocabularies_url
      end
    end

    ##
    # Responds to POST /admin/vocabularies/import
    #
    def import
      begin
        raise 'No vocabulary specified.' if params[:vocabulary].blank?

        json = params[:vocabulary].read.force_encoding('UTF-8')
        vocab = Vocabulary.from_json(json)
        vocab.save!
      rescue => e
        handle_error(e)
        redirect_to admin_vocabularies_path
      else
        flash['success'] = "Vocabulary imported as #{vocab.name}."
        redirect_to admin_vocabularies_path
      end
    end

    ##
    # Responds to GET /admin/vocabularies
    #
    def index
      @vocabularies = Vocabulary.all.order(:name)
      @vocabulary = Vocabulary.new # for the new-vocabulary form
    end

    ##
    # Responds to GET /admin/vocabularies/:id
    #
    def show
      @vocabulary = Vocabulary.find(params[:id])

      respond_to do |format|
        format.html do
          @new_vocabulary_term = VocabularyTerm.new(vocabulary_id: @vocabulary.id)
        end
        format.json do
          filename = "#{CGI.escape(@vocabulary.name)}.json"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
          render plain: JSON.pretty_generate(@vocabulary.as_json)
        end
      end
    end

    ##
    # Responds to GET /admin/vocabularies/:id/terms.json?query=&type={string,uri}
    #
    def terms
      @vocabulary = Vocabulary.find(params[:vocabulary_id])

      respond_to do |format|
        format.json do
          type = %w(string uri).include?(params[:type]) ?
              params[:type] : 'string'
          render json: @vocabulary.vocabulary_terms.
              where("LOWER(#{type}) LIKE ?", "%#{params[:query].downcase}%").
              order(:string, :uri).limit(50)
        end
      end
    end

    def update
      @vocabulary = Vocabulary.find(params[:id])
      if request.xhr?
        begin
          @vocabulary.update!(sanitized_params)
        rescue ActiveRecord::RecordInvalid
          response.headers['X-PearTree-Result'] = 'error'
          render partial: 'shared/validation_messages',
                 locals: { entity: @vocabulary }
        rescue => e
          handle_error(e)
          keep_flash
          render 'update'
        else
          response.headers['X-PearTree-Result'] = 'success'
          flash['success'] = "Vocabulary \"#{@vocabulary.name}\" updated."
          keep_flash
          render 'update' # update.js.erb will reload the page
        end
      else
        begin
          @vocabulary.update!(sanitized_params)
        rescue ActiveRecord::RecordInvalid
          response.headers['X-PearTree-Result'] = 'error'
          render 'show'
        rescue => e
          handle_error(e)
          render 'show'
        else
          response.headers['X-PearTree-Result'] = 'success'
          flash['success'] = "Vocabulary \"#{@vocabulary.name}\" updated."
          redirect_back fallback_location: admin_vocabulary_path(@vocabulary)
        end
      end
    end

    private

    def sanitized_params
      params.require(:vocabulary).permit(PERMITTED_PARAMS)
    end

    def set_permitted_params
      @permitted_params = params.permit(PERMITTED_PARAMS)
    end

  end

end
