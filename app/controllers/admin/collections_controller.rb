module Admin

  class CollectionsController < ControlPanelController

    before_action :create_rbac, only: :create
    before_action :delete_rbac, only: :destroy
    before_action :update_rbac, only: :update

    def create
      command = CreateCollectionCommand.new(sanitized_repo_params)
      @collection = command.object
      begin
        executor.execute(command)
      rescue ActiveMedusa::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @collection }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render partial: 'form', locals: { collection: @collection,
                                          context: :create }
      else
        Solr::Solr.client.commit
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Collection \"#{@collection.title}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      @collection = Collection.find(params[:id])

      command = DeleteCollectionCommand.new(@collection)
      begin
        executor.execute(command)
      rescue => e
        flash['error'] = "#{e}"
        redirect_to admin_repository_collection_url(@collection)
      else
        flash['success'] = "Collection \"#{@collection.title}\" deleted."
        redirect_to admin_repository_collections_url
      end
    end

    def index
      @start = params[:start] ? params[:start].to_i : 0
      @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
      @collections = Collection.order(Solr::Fields::TITLE).start(@start).limit(@limit)
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
      @num_shown = [@limit, @collections.total_length].min
      @collection = Collection.new
    end

    ##
    # Responds to PATCH /admin/collections/:key/publish
    #
    def publish
      @collection = Repository::Collection.find_by_key(
          params[:repository_collection_key])
      raise ActiveRecord::RecordNotFound unless @collection

      args = {
          command: PublishCollectionCommand,
          args: @collection,
          task_status_text: "Publish collection \"#{@collection.title}\""
      }
      job_runner.run_later(CommandJob, args)

      flash['success'] = 'Collection queued for publishing.'
      redirect_to :back
    end

    def show
      @collection = Repository::Collection.find_by_key(params[:key])
      raise ActiveRecord::RecordNotFound unless @collection

      @metadata_profile_options_for_select = MetadataProfile.order(:name).
          map{ |t| [ t.name, t.id ] }
      @theme_options_for_select = [[ 'None (Use Global)', nil ]] +
          Theme.order(:name).map{ |t| [ t.name, t.id ] }
    end

    ##
    # Responds to PATCH /admin/collections/:key/unpublish
    #
    def unpublish
      @collection = Repository::Collection.find_by_key(
          params[:repository_collection_key])
      raise ActiveRecord::RecordNotFound unless @collection

      args = {
          command: UnpublishCollectionCommand,
          args: @collection,
          task_status_text: "Unpublish collection \"#{@collection.title}\""
      }
      job_runner.run_later(CommandJob, args)

      flash['success'] = 'Collection queued for unpublishing.'
      redirect_to :back
    end

    def update
      @collection = Repository::Collection.find_by_key(params[:key])
      raise ActiveRecord::RecordNotFound unless @collection

      if params[:repository_collection]
        command = UpdateRepositoryCollectionCommand.new(@collection,
                                                        sanitized_repo_params)
        begin
          executor.execute(command)
        rescue ActiveMedusa::RecordInvalid
          response.headers['X-PearTree-Result'] = 'error'
          render partial: 'shared/validation_messages',
                 locals: { entity: @collection }
        rescue => e
          response.headers['X-PearTree-Result'] = 'error'
          flash['error'] = "#{e}"
          keep_flash
          render partial: 'form', locals: { collection: @collection,
                                            context: :edit }
        else
          Solr::Solr.client.commit
          response.headers['X-PearTree-Result'] = 'success'
          flash['success'] = "Collection \"#{@collection.title}\" updated."
          keep_flash
          render 'create' # create.js.erb will reload the page
        end
      else
        command = UpdateDBCollectionCommand.new(@collection.db_counterpart,
                                                sanitized_db_params)
        begin
          executor.execute(command)
        rescue => e
          response.headers['X-PearTree-Result'] = 'error'
          flash['error'] = "#{e}"
          render 'edit' unless request.xhr?
        else
          response.headers['X-PearTree-Result'] = 'success'
          flash['success'] = "Collection \"#{@collection.title}\" updated."
          keep_flash
          render 'update' # update.js.erb will reload the page
        end
      end
    end

    private

    def create_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::COLLECTIONS_CREATE)
    end

    def delete_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::COLLECTIONS_DELETE)
    end

    def sanitized_db_params
      params.require(:db_collection).permit(:id, :metadata_profile_id,
                                            :theme_id)
    end

    def sanitized_repo_params
      params.require(:repository_collection).permit(:description, :key,
                                                    :published, :title)
    end

    def update_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::COLLECTIONS_UPDATE)
    end

  end

end
