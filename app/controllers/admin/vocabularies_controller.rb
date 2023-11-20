# frozen_string_literal: true

module Admin

  class VocabulariesController < ControlPanelController

    PERMITTED_PARAMS = [:key, :name]

    before_action :set_permitted_params
    before_action :set_vocabulary, except: [:create, :import, :index]
    before_action :authorize_vocabulary, except: [:create, :import, :index]

    def create
      @vocabulary = Vocabulary.new(sanitized_params)
      authorize(@vocabulary)
      begin
        @vocabulary.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @vocabulary }
      rescue => e
        handle_error(e)
        keep_flash
        render 'admin/shared/reload'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Vocabulary \"#{@vocabulary.name}\" created."
        keep_flash
        render 'admin/shared/reload'
      end
    end

    ##
    # Responds to `POST /vocabularies/:id/delete-vocabulary-terms`
    #
    def delete_vocabulary_terms
      if params[:vocabulary_terms]&.respond_to?(:each)
        count = params[:vocabulary_terms].length
        if count > 0
          ActiveRecord::Base.transaction do
            @vocabulary.vocabulary_terms.where(id: params[:vocabulary_terms]).destroy_all
          end
          flash['success'] = "Deleted #{count} vocabulary term(s)."
        end
      else
        flash['error'] = 'No vocabulary terms to delete (none checked).'
      end
      redirect_back fallback_location: admin_vocabulary_path(@vocabulary)
    end

    def destroy
      @vocabulary.destroy!
    rescue => e
      handle_error(e)
    else
      flash['success'] = "Vocabulary \"#{@vocabulary.name}\" deleted."
    ensure
      redirect_to admin_vocabularies_url
    end

    ##
    # Responds to `POST /admin/vocabularies/import`
    #
    def import
      raise 'No vocabulary specified.' if params[:vocabulary].blank?
      json = params[:vocabulary].read.force_encoding('UTF-8')
      vocab = Vocabulary.from_json(json)
      authorize(vocab)
      vocab.save!
    rescue => e
      handle_error(e)
      redirect_to admin_vocabularies_path
    else
      flash['success'] = "Vocabulary imported as #{vocab.name}."
      redirect_to admin_vocabularies_path
    end

    ##
    # Responds to `GET /admin/vocabularies`
    #
    def index
      authorize(Vocabulary)
      @vocabularies = Vocabulary.all.order(:name)
      @vocabulary   = Vocabulary.new # for the new-vocabulary form
    end

    ##
    # Responds to `GET /admin/vocabularies/:id`
    #
    def show
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

    def update
      if request.xhr?
        begin
          @vocabulary.update!(sanitized_params)
        rescue ActiveRecord::RecordInvalid
          response.headers['X-Kumquat-Result'] = 'error'
          render partial: 'shared/validation_messages',
                 locals: { entity: @vocabulary }
        rescue => e
          handle_error(e)
          keep_flash
          render 'admin/shared/reload'
        else
          response.headers['X-Kumquat-Result'] = 'success'
          flash['success'] = "Vocabulary \"#{@vocabulary.name}\" updated."
          keep_flash
          render 'admin/shared/reload'
        end
      else
        begin
          @vocabulary.update!(sanitized_params)
        rescue ActiveRecord::RecordInvalid
          response.headers['X-Kumquat-Result'] = 'error'
          render 'show'
        rescue => e
          handle_error(e)
          render 'show'
        else
          response.headers['X-Kumquat-Result'] = 'success'
          flash['success'] = "Vocabulary \"#{@vocabulary.name}\" updated."
          redirect_back fallback_location: admin_vocabulary_path(@vocabulary)
        end
      end
    end


    private

    def authorize_vocabulary
      @vocabulary ? authorize(@vocabulary) : skip_authorization
    end

    def sanitized_params
      params.require(:vocabulary).permit(PERMITTED_PARAMS)
    end

    def set_permitted_params
      @permitted_params = params.permit(PERMITTED_PARAMS)
    end

    def set_vocabulary
      @vocabulary = Vocabulary.find(params[:id] || params[:vocabulary_id])
    end

  end

end
