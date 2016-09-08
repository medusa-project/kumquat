##
# Handles requests to CONTENTdm URI paths. A CONTENTdm domain can then be
# redirected to a DLS instance to enable straightforward redirection of
# CONTENTdm resources to DLS resources.
#
class ContentdmController < ApplicationController

  ##
  # Responds to GET /cdm/landingpage/collection/:alias
  #
  def redirect_to_dls_collection
    col = Collection.find_by_contentdm_alias(params[:alias])
    raise ActiveRecord::RecordNotFound unless col
    redirect_to collection_url(col)
  end

  ##
  # Responds to:
  # GET /cdm/ref/collection/:alias/:pointer
  # GET /cdm/singleitem/collection/:alias/id/:pointer
  # GET /cdm/compoundobject/collection/:alias/id/:pointer
  #
  def redirect_to_dls_item
    item = Item.where(contentdm_alias: params[:alias],
                      contentdm_pointer: params[:pointer]).limit(1).first
    raise ActiveRecord::RecordNotFound unless item
    redirect_to item_url(item)
  end

end
