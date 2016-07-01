module Admin

  class VocabulariesController < ControlPanelController

    def create
      @vocabulary = Vocabulary.new(sanitized_params)
      begin
        @vocabulary.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @vocabulary }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Vocabulary \"#{@vocabulary.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      vocabulary = Vocabulary.find(params[:id])
      begin
        vocabulary.destroy!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = "Vocabulary \"#{vocabulary.name}\" deleted."
      ensure
        redirect_to admin_vocabularies_url
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
          response.headers['X-PearTree-Result'] = 'error'
          flash['error'] = "#{e}"
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
          response.headers['X-PearTree-Result'] = 'error'
          flash['error'] = "#{e}"
          render 'show'
        else
          response.headers['X-PearTree-Result'] = 'success'
          flash['success'] = "Vocabulary \"#{@vocabulary.name}\" updated."
          redirect_to :back
        end
      end
    end

    private

    def sanitized_params
      params.require(:vocabulary).permit(:key, :name)
    end

  end

end
