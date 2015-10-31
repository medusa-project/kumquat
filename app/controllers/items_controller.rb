class ItemsController < ApplicationController

  def index
    @items = Item.all
  end

  def show
    @item = Item.find_by_web_id_si(params[:web_id])
    raise ActiveRecord::RecordNotFound unless @item
  end

end
