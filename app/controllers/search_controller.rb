##
# Handles cross-entity "global" searching and harvesting.
#
class SearchController < WebsiteController

  PERMITTED_PARAMS = [:_, :collection_id, { fq: [] }, :q, :sort, :start, :utf8]

  before_action :set_sanitized_params, only: :search

  ##
  # Used for harvesting. Returns only JSON.
  #
  # Responds to GET /harvest
  #
  def harvest
    @start = params[:start].to_i
    @limit = limit

    # EntityFinder will search across entity classes and return Items, Agents,
    # and Collections.
    finder = EntityFinder.new.
        user_roles(request_roles).
        # exclude all variants except File
        exclude_item_variants(*Item::Variants::all.reject{ |v| v == Item::Variants::FILE }).
        start(@start).
        limit(@limit)

    if params[:last_modified_before].present?
      finder = finder.last_modified_before(Time.at(params[:last_modified_before].to_i))
    end
    if params[:last_modified_after].present?
      finder = finder.last_modified_after(Time.at(params[:last_modified_after].to_i))
    end

    @entities = finder.to_a
    @count    = finder.count

    render json: {
        start: @start,
        limit: @limit,
        numResults: @count,
        results: @entities.map { |entity|
          {
              id: entity.repository_id,
              uri: url_for(entity)
          }
        }
    }
  end

  ##
  # Responds to GET /search
  #
  def search
    @start = params[:start].to_i
    @limit = limit

    # EntityFinder will search across entity classes and return both Items and
    # Collections.
    finder = EntityFinder.new.
        user_roles(request_roles).
        # exclude all variants except File
        exclude_item_variants(*Item::Variants::all.reject{ |v| v == Item::Variants::FILE }).
        facet_filters(params[:fq]).
        # TODO: why does the underscore cause collections to sort first, which is exactly what we want?
        order(params[:sort].present? ? params[:sort] : '_').
        start(@start).
        limit(@limit)

    if params[:field].present?
      finder = finder.query(params[:field], params[:q])
    else
      finder = finder.query_all(params[:q])
    end

    @entities          = finder.to_a
    @facets            = finder.facets
    @current_page      = finder.page
    @count             = finder.count
    @num_results_shown = [@limit, @count].min
    @metadata_profile  = MetadataProfile.default

    # If there are no results, get some search suggestions.
    if @count < 1 and params[:q].present?
      @suggestions = finder.suggestions
    end

    respond_to do |format|
      format.html
      format.atom do
        @updated = @entities.any? ?
                       @entities.map(&:updated_at).sort{ |d| d <=> d }.last : Time.now
      end
      format.js
      format.json do
        render json: {
            start: @start,
            limit: @limit,
            numResults: @count,
            results: @entities.map { |entity|
              {
                  id: entity.repository_id,
                  uri: url_for(entity)
              }
            }
        }
      end
    end
  end

  private

  def limit
    limit = params[:limit].to_i
    if limit < MIN_RESULT_WINDOW or limit > MAX_RESULT_WINDOW
      limit = Option::integer(Option::Keys::DEFAULT_RESULT_WINDOW)
    end
    limit
  end

  def set_sanitized_params
    @permitted_params = params.permit(PERMITTED_PARAMS)
  end

end
