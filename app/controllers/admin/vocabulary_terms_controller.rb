# frozen_string_literal: true

module Admin

  class VocabularyTermsController < ControlPanelController

    before_action :set_vocabulary_term, except: [:create, :index]
    before_action :authorize_vocabulary_term, except: [:create, :index]

    ##
    # XHR only
    #
    def create
      @term = VocabularyTerm.new(sanitized_params)
      authorize(@term)
      @term.save!
    rescue ActiveRecord::RecordInvalid
      response.headers['X-Kumquat-Result'] = 'error'
      render partial: 'shared/validation_messages',
             locals: { entity: @term }
    rescue => e
      handle_error(e)
      keep_flash
      render 'admin/shared/reload'
    else
      response.headers['X-Kumquat-Result'] = 'success'
      flash['success'] = "Vocabulary term \"#{@term}\" created."
      keep_flash
      render 'admin/shared/reload'
    end

    def destroy
      vocab = @term.vocabulary
      @term.destroy!
    rescue => e
      handle_error(e)
    else
      flash['success'] = "Vocabulary term \"#{@term}\" deleted."
    ensure
      redirect_back fallback_location: admin_vocabulary_vocabulary_terms_path(vocab)
    end

    ##
    # XHR only
    #
    def edit
      render partial: 'admin/vocabulary_terms/form',
             locals:  { vocabulary_term: @term }
    end

    ##
    # This is used for autocompleting element values as well as in the Batch
    # Change modal.
    #
    # Responds to `GET /admin/vocabularies/:id/terms.json?query=&type={string,uri}`
    #
    def index
      vocabulary = Vocabulary.find(params[:vocabulary_id])
      authorize(vocabulary)
      respond_to do |format|
        format.json do
          terms = vocabulary.vocabulary_terms.order(:string, :uri)
          if params[:query].present?
            type = %w(string uri).include?(params[:type]) ?
                     params[:type] : 'string'
            terms = terms.where("LOWER(#{type}) LIKE ?", "%#{params[:query].downcase}%")
          end
          render json: terms
        end
      end
    end

    ##
    # XHR only
    #
    def update
      @term.update!(sanitized_params)
    rescue ActiveRecord::RecordInvalid
      response.headers['X-Kumquat-Result'] = 'error'
      render partial: 'shared/validation_messages',
             locals: { entity: @term }
    rescue => e
      handle_error(e)
      keep_flash
      render 'admin/shared/reload'
    else
      response.headers['X-Kumquat-Result'] = 'success'
      flash['success'] = "Vocabulary term \"#{@term}\" updated."
      keep_flash
      render 'admin/shared/reload'
    end


    private

    def authorize_vocabulary_term
      @term ? authorize(@term) : skip_authorization
    end

    def sanitized_params
      params.require(:vocabulary_term).permit(:string, :uri, :vocabulary_id)
    end

    def set_vocabulary_term
      @term = VocabularyTerm.find(params[:id])
    end

  end

end
