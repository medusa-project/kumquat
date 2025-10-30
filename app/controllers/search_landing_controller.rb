class SearchLandingController < ApplicationController
  PERMITTED_PARAMS = [{ fq: [] }, :q, :sort, :start, :utf8]

  before_action :set_sanitized_params
  def index
    @limit = window_size.to_i
    @start = [@permitted_params[:start].to_i.abs, 0].max 

    if params[:query].present? || params[:field].present?
      relation = ItemRelation.new 
      process_search_query(relation)
      @items = relation.start(@start).limit(@limit).to_a           
    # @count          = relation.count.to_i 
    # How do I get this count without going through the Gateway?
      @count          = GatewayClient.instance.special_collections_num_items 
    else 
      collections = Collection.where(published_in_dls: true)
      collection_ids = collections.pluck(:repository_id)

      relation = Item.search 
                    .collections(collection_ids)
      @items = relation.start(@start).limit(@limit).to_a 
      # @count = relation.count.to_i 
      @count          = GatewayClient.instance.special_collections_num_items
    end
    @current_page = (@start / @limit) + 1 
  end 

  private 

  def set_sanitized_params
    @permitted_params = params.permit(PERMITTED_PARAMS)
  end

  def window_size 
    40 
  end


                  

    ## The below count only gives about 1,000 which is far lower than the expected 316k from the above
    #
    # collections = Collection.where(published_in_dls: true).pluck(:repository_id)
    # @item_count = ItemRelation.new.filter('sys_k_collection', collections).count 


    # @results = nil 
    # if params[:query].present? || params[:field].present?
    #   relation = ItemRelation.new 
    #   process_search_query(relation)
    #   @results = relation.to_a
    # end
end