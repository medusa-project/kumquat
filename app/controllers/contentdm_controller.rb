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
    # Try to redirect to the collection itself.
    col = Collection.find_by_contentdm_alias(params[:alias])
    if col
      redirect_to collection_url(col)
    else
      # If it doesn't exist, redirect to the landing page.
      redirect_to root_url
    end
  end

  ##
  # Responds to:
  # GET /cdm/ref/collection/:alias/:pointer
  # GET /cdm/singleitem/collection/:alias/id/:pointer
  # GET /cdm/compoundobject/collection/:alias/id/:pointer
  #
  def redirect_to_dls_item
    # Try to redirect to the item itself.
    item = Item.where(contentdm_alias: params[:alias],
                      contentdm_pointer: params[:pointer]).limit(1).first
    if item
      redirect_to item_url(item)
    else
      # If there is no item with the given pointer, but the collection is
      # valid, redirect to that.
      col = Collection.find_by_contentdm_alias(params[:alias])
      if col
        redirect_to collection_url(col)
      else
        # Otherwise, redirect to the landing page.
        redirect_to root_url
      end
    end
  end

end
