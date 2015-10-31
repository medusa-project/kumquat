class CollectionsController < ApplicationController

  def index
    @collections = Collection.all
  end

  def show
    @collection = Collection.find_by_web_id_si(params[:web_id])
    raise ActiveRecord::RecordNotFound unless @collection
  end

end
