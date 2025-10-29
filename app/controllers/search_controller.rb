class SearchController < ApplicationController
  include Search 

  def index
    @item_count = GatewayClient.instance.special_collections_num_items

    ## The below count only gives about 1,000 which is far lower than the expected 316k from the above
    #
    # collections = Collection.where(published_in_dls: true).pluck(:repository_id)
    # @item_count = ItemRelation.new.filter('sys_k_collection', collections).count 


    @results = nil 
    if params[:query].present? || params[:field].present?
      relation = ItemRelation.new 
      process_search_query(relation)
      @results = relation.to_a
    end
  end
end