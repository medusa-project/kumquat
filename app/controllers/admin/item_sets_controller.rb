# frozen_string_literal: true

module Admin

  class ItemSetsController < ControlPanelController

    before_action :set_item_set, except: [:create, :new]
    before_action :authorize_item_set, except: [:create, :new]

    ##
    # Responds to `POST /admin/collections/:collection_id/item_sets`
    #
    def create
      item_set = ItemSet.new(permitted_params)
      authorize(item_set)
      item_set.save!
    rescue ActiveRecord::RecordInvalid
      response.headers['X-Kumquat-Result'] = 'error'
      render partial: 'shared/validation_messages',
             locals: { entity: item_set }
    rescue => e
      handle_error(e)
      keep_flash
      render 'admin/shared/reload'
    else
      response.headers['X-Kumquat-Result'] = 'success'
      flash['success'] = "Set \"#{item_set}\" created."
      keep_flash
      render 'admin/shared/reload'
    end

    ##
    # Responds to `DELETE /admin/collections/:collection_id/item_sets/:id`
    #
    def destroy
      collection = @item_set.collection
      @item_set.destroy!

      flash['success'] = "#{@item_set} deleted."
      redirect_to admin_collection_path(collection)
    end

    ##
    # Responds to `GET /admin/collections/:collection_id/item_sets/:id/edit`
    #
    def edit
      render partial: 'form', locals: { collection: @item_set.collection,
                                        item_set:   @item_set }
    end

    ##
    # Responds to `GET /admin/collections/:collection_id/item_sets/:item_set_id/items`
    #
    def items
      @items = Item.search.
          aggregations(false).
          include_unpublished(true).
          include_publicly_inaccessible(true).
          include_restricted(true).
          filter(Item::IndexFields::ITEM_SETS, @item_set.id).
          order(Item::IndexFields::TITLE)

      headers['Content-Disposition'] = 'attachment; filename="items.tsv"'
      headers['Content-Type']        = 'text/tab-separated-values'
      render plain: ItemTsvExporter.new.items_in_item_set(@item_set)
    end

    ##
    # Responds to `GET /admin/collections/:collection_id/item_sets/new`
    #
    def new
      collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless collection

      new_item_set = ItemSet.new
      authorize(new_item_set)
      render partial: 'form', locals: { collection: collection,
                                        item_set: new_item_set }
    end

    ##
    # Responds to `DELETE /admin/collections/:collection_id/item_sets/:item_set_id/all-items`
    #
    def remove_all_items
      ActiveRecord::Base.transaction do
        @item_set.items.destroy_all
      end

      flash['success'] = "Removed all items from #{@item_set}."

      redirect_back fallback_location: admin_collection_item_set_path(params[:collection_id],
                                                                      params[:item_set_id])
    end

    ##
    # Responds to `DELETE /admin/collections/:collection_id/item_sets/:item_set_id/items`
    #
    def remove_items
      item_ids = params[:items]
      if item_ids&.any?
        item_set = ItemSet.find(params[:item_set_id])
        items_to_delete = item_set.items.where('repository_id IN (?)', item_ids)

        ActiveRecord::Base.transaction do
          items_to_delete.each do |item|
            item_set.items.delete(item.all_children)
            item_set.items.delete(item)
          end
        end

        flash['success'] = "Removed #{item_ids.length} item(s) from #{item_set}."
      else
        flash['error'] = 'No items are checked.'
      end

      RefreshOpensearchJob.perform_later
      redirect_back fallback_location: admin_collection_item_set_path(params[:collection_id],
                                                                      params[:item_set_id])
    end

    ##
    # Responds to `GET /admin/collections/:collection_id/item_sets/:id`
    #
    def show
      @start        = params[:start].to_i
      @limit        = Setting::integer(Setting::Keys::DEFAULT_RESULT_WINDOW)
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 

      @items = Item.search.
          aggregations(false).
          include_unpublished(true).
          include_publicly_inaccessible(true).
          include_restricted(true).
          filter(Item::IndexFields::ITEM_SETS, @item_set.id).
          order(Item::IndexFields::TITLE).
          start(@start).
          limit(@limit)
      @count = @items.count
    end

    ##
    # Responds to `POST /admin/collections/:collection_id/item_sets/:id`
    #
    def update
      @item_set.update!(permitted_params)
    rescue ActiveRecord::RecordInvalid
      response.headers['X-Kumquat-Result'] = 'error'
      render partial: 'shared/validation_messages',
             locals: { entity: @item_set }
    rescue => e
      handle_error(e)
      keep_flash
      render 'admin/shared/reload'
    else
      response.headers['X-Kumquat-Result'] = 'success'
      flash['success'] = "Set \"#{@item_set}\" updated."
      keep_flash
      render 'admin/shared/reload'
    end


    private

    def authorize_item_set
      @item_set ? authorize(@item_set) : skip_authorization
    end

    def permitted_params
      params.require(:item_set).permit(:id, :collection_repository_id, :name,
                                       user_ids: [])
    end

    def set_item_set
      @item_set = ItemSet.find(params[:id] || params[:item_set_id])
    end

  end

end
