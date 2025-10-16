class SearchController < ApplicationController
  include Search 

  def index 
    @results = nil 
    if params[:query].present? || params[:field].present?
      relation = ItemRelation.new 
      process_search_query(relation)
      @results = relation.to_a
    end
  end
end