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
    if col
      redirect_to collection_url(col), status: 301
    else
      redirect_to root_url, status: 301
    end
  end

  ##
  # Responds to:
  # GET /cdm/ref/collection/:alias/:pointer
  # GET /cdm/ref/collection/:alias/id/:pointer
  # GET /cdm/singleitem/collection/:alias/id/:pointer
  # GET /cdm/singleitem/collection/:alias/id/:pointer/rec/:noop
  # GET /cdm/compoundobject/collection/:alias/id/:pointer
  #
  def redirect_to_dls_item
    # Try to redirect to the most relevant resource.
    item = Item.where(contentdm_alias: params[:alias],
                      contentdm_pointer: params[:pointer]).limit(1).first
    if item
      redirect_to item_url(item), status: 301
    else
      item = Item.joins('LEFT JOIN collections ON items.collection_repository_id = collections.repository_id').
          where('collections.contentdm_alias': params[:alias],
                contentdm_pointer: params[:pointer]).limit(1).first
      if item
        redirect_to item_url(item), status: 301
      else
        col = Collection.find_by_contentdm_alias(params[:alias])
        if col
          redirect_to collection_url(col), status: 301
        else
          redirect_to root_url, status: 301
        end
      end
    end
  end

end
