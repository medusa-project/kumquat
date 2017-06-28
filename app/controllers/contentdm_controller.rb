##
# Handles requests to CONTENTdm URI paths. A CONTENTdm domain can then be
# redirected to a DLS instance to enable straightforward redirection of
# CONTENTdm resources to DLS resources.
#
class ContentdmController < ApplicationController

  ##
  # Responds to:
  #
  # * GET /projects/*
  # * GET /ui/cdm/*
  # * GET /utils/*
  #
  def gone
    render text: 'This resource no longer exists.', status: :gone
  end

  ##
  # Handles CONTENTdm v4 results URLs. (CONTENTdm 4 doesn't have
  # collection-specific pages, so these redirect to DLS collection pages.)
  #
  # Responds to GET /cdm4/browse.php
  #
  def v4_collection
    col = Collection.find_by_contentdm_alias(sanitize_alias(params[:CISOROOT]))
    if col
      redirect_to collection_url(col), status: 301
    else
      redirect_to collections_url, status: 303
    end
  end

  ##
  # Handles CONTENTdm v4 results URLs.
  #
  # Responds to GET /cdm4/results.php
  #
  def v4_collection_items
    col = Collection.find_by_contentdm_alias(sanitize_alias(params[:CISOROOT]))
    if col
      redirect_to collection_items_url(col), status: 301
    else
      redirect_to collections_url, status: 303
    end
  end

  ##
  # Handles CONTENTdm v4 item URLs.
  #
  # Responds to:
  # * GET /cdm4/item_viewer.php
  # * GET /cdm4/document.php
  #
  def v4_item
    redirect_to_best_match(params[:CISOROOT], params[:CISOPTR])
  end

  ##
  # Handles CONTENTdm v4 reference URLs, which look like: /u?/alias,pointer
  #
  # Responds to GET /u
  #
  def v4_reference_url
    identifier = params.keys.select{ |k| k.start_with?('/') }.first
    if identifier
      parts = identifier.split(',')
      if parts.length == 2
        redirect_to_best_match(sanitize_alias(parts[0]), parts[1].to_i)
        return
      end
    end
    redirect_to root_url, status: 301
  end

  ##
  # Handles CONTENTdm v6 collection URLs.
  #
  # Responds to:
  #
  # * GET /cdm/landingpage/collection/:alias
  # * GET /cdm/about/collection/:alias
  #
  def v6_collection
    col = Collection.find_by_contentdm_alias(params[:alias])
    if col
      redirect_to collection_url(col), status: 301
    else
      redirect_to collections_url, status: 303
    end
  end

  ##
  # Handles CONTENTdm v6 collection items URLs.
  #
  # Responds to:
  # * GET /cdm/search/collection/:alias
  # * GET /cdm/search/collection/:alias/searchterm/:term/field/:field/mode/:mode/conn/:conn/order/:order
  #
  def v6_collection_items
    col = Collection.find_by_contentdm_alias(sanitize_alias(params[:alias]))
    if col
      if params[:term]
        redirect_to collection_items_url(col, q: sanitize_term(params[:term])),
                    status: 301
      else
        redirect_to collection_items_url(col), status: 301
      end
    else
      redirect_to collections_url, status: 303
    end
  end

  ##
  # Handles CONTENTdm v6 item URLs.
  #
  # Responds to:
  # * GET /cdm/ref/collection/:alias/:pointer
  # * GET /cdm/ref/collection/:alias/id/:pointer
  # * GET /cdm/singleitem/collection/:alias/id/:pointer
  # * GET /cdm/singleitem/collection/:alias/id/:pointer/rec/:noop
  # * GET /cdm/compoundobject/collection/:alias/id/:pointer
  # * GET /cdm/compoundobject/collection/:alias/id/:pointer/rec/:noop
  # * GET /cdm/compoundobject/collection/:alias/id/:pointer/show/:pointer/rec/:noop
  #
  def v6_item
    redirect_to_best_match(params[:alias], params[:pointer])
  end

  ##
  # Handles CONTENTdm 6 search results URLs.
  #
  # Responds to:
  #
  # * GET /cdm/search/searchterm/:term
  # * GET /cdm/search/searchterm/:term/mode/:mode
  # * GET /cdm/search/searchterm/:term/mode/:mode/page/:page
  # * GET /cdm/search/searchterm/:term/mode/:mode/order/:order
  # * GET /cdm/search/searchterm/:term/mode/:mode/order/:order/ad/desc
  #
  def v6_search_results
    redirect_to search_url(q: sanitize_term(params[:term])), status: 301
  end

  private

  def redirect_to_best_match(alias_, pointer)
    alias_ = sanitize_alias(alias_)
    item = Item.where(contentdm_alias: alias_,
                      contentdm_pointer: pointer).limit(1).first
    if item
      redirect_to item_url(item), status: 301
    else
      item = Item.joins('LEFT JOIN collections ON items.collection_repository_id = collections.repository_id').
          where('collections.contentdm_alias': alias_,
                contentdm_pointer: pointer).limit(1).first
      if item
        redirect_to item_url(item), status: 301
      else
        col = Collection.find_by_contentdm_alias(alias_)
        if col
          redirect_to collection_url(col), status: 303
        else
          redirect_to root_url, status: 303
        end
      end
    end
  end

  def sanitize_alias(alias_)
    alias_&.gsub(/[^A-Za-z0-9_]/i, '')
  end

  ##
  # CONTENTdm has its own allowed term syntax which we don't support.
  # This will filter the term to allow only alphanumerics and spaces.
  #
  def sanitize_term(term)
    term.gsub(/[^a-z0-9 ]/i, '')
  end

end
