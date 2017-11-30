module Admin

  class ItemSetsController < ControlPanelController

    before_action :check_authorization, except: [:new, :create]

    ##
    # Responds to POST /admin/collections/:collection_id/item_sets
    #
    def create
      begin
        item_set = ItemSet.new(sanitized_params)
        item_set.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: item_set }
      rescue => e
        handle_error(e)
        keep_flash
        render 'create'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Set \"#{item_set}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    ##
    # Responds to DELETE /admin/collections/:collection_id/item_sets/:id
    #
    def destroy
      item_set = ItemSet.find(params[:id])
      col = item_set.collection
      item_set.destroy!

      flash['success'] = "#{item_set} deleted."
      redirect_to admin_collection_path(col)
    end

    ##
    # Responds to GET /admin/collections/:collection_id/item_sets/:id/edit
    #
    def edit
      item_set = ItemSet.find(params[:id])
      render partial: 'form', locals: { collection: item_set.collection,
                                        item_set: item_set,
                                        context: :edit }
    end

    ##
    # Responds to GET /admin/collections/:collection_id/item_sets/:item_set_id/items
    #
    def items
      @item_set = ItemSet.find(params[:item_set_id])
      finder = ItemFinder.new.
          aggregations(false).
          filter(Item::IndexFields::ITEM_SETS, @item_set.id).
          order(Item::IndexFields::TITLE)
      @items = finder.to_a

      headers['Content-Disposition'] = 'attachment; filename="items.tsv"'
      headers['Content-Type'] = 'text/tab-separated-values'
      render plain: ItemTsvExporter.new.items_in_item_set(@item_set)
    end

    ##
    # Responds to GET /admin/collections/:collection_id/item_sets/new
    #
    def new
      collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless collection

      new_item_set = ItemSet.new
      render partial: 'form', locals: { collection: collection,
                                        item_set: new_item_set,
                                        context: :new }
    end

    ##
    # Responds to DELETE /admin/collections/:collection_id/item_sets/:item_set_id/all-items
    #
    def remove_all_items
      item_set = ItemSet.find(params[:item_set_id])
      ActiveRecord::Base.transaction do
        item_set.items.destroy_all
      end

      flash['success'] = "Removed all items from #{item_set}."

      redirect_back fallback_location: admin_collection_item_set_path(params[:collection_id],
                                                                      params[:item_set_id])
    end

    ##
    # Responds to DELETE /admin/collections/:collection_id/item_sets/:item_set_id/items
    #
    def remove_items
      item_ids = params[:items]
      if item_ids&.any?
        item_set = ItemSet.find(params[:item_set_id])
        items_to_delete = item_set.items.where('repository_id IN (?)', item_ids)
        ActiveRecord::Base.transaction do
          item_set.items.delete(items_to_delete)
        end

        flash['success'] = "Removed #{item_ids.length} items from #{item_set}."
      else
        flash['error'] = 'No items are checked.'
      end
      redirect_back fallback_location: admin_collection_item_set_path(params[:collection_id],
                                                                      params[:item_set_id])
    end

    ##
    # Responds to GET /admin/collections/:collection_id/item_sets/:id
    #
    def show
      @item_set = ItemSet.find(params[:id])

      @start = params[:start].to_i
      @limit = Option::integer(Option::Keys::DEFAULT_RESULT_WINDOW)
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1

      finder = ItemFinder.new.
          aggregations(false).
          filter(Item::IndexFields::ITEM_SETS, @item_set.id).
          order(Item::IndexFields::TITLE).
          start(@start).
          limit(@limit)
      @items = finder.to_a
      @count = finder.count
    end

    ##
    # Responds to POST /admin/collections/:collection_id/item_sets/:id
    #
    def update
      item_set = ItemSet.find(params[:id])
      begin
        item_set.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: item_set }
      rescue => e
        handle_error(e)
        keep_flash
        render 'update'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Set \"#{item_set}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    ##
    # Checks whether a user is a member of the set, and redirects to the
    # collection page if not.
    #
    def check_authorization
      item_set = ItemSet.find(params[:id] || params[:item_set_id])
      unless item_set.users.include?(current_user)
        flash['error'] = "You are not authorized to access #{item_set}."
        redirect_to(admin_collection_path(item_set.collection))
      end
    end

    def sanitized_params
      params.require(:item_set).permit(:id, :collection_repository_id, :name,
                                       user_ids: [])
    end

  end

end
