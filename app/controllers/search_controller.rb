##
# Handles cross-entity "global" searching.
#
class SearchController < WebsiteController

  PERMITTED_PARAMS = [:_, :collection_id, { fq: [] }, :q, :sort, :start, :utf8]

  before_action :search, :set_sanitized_params

  ##
  # Responds to GET /search
  #
  def search
    @start = params[:start].to_i
    @limit = Option::integer(Option::Keys::RESULTS_PER_PAGE)

    # EntityFinder will search across entity classes and return both Items and
    # Collections.
    finder = EntityFinder.new.
        user_roles(request_roles).
        # exclude all variants except File
        exclude_item_variants(*Item::Variants::all.reject{ |v| v == Item::Variants::FILE }).
        only_described(true).
        query_all(params[:q]).
        facet_filters(params[:fq]).
        order(params[:sort]).
        start(@start).
        limit(@limit)
    @entities = finder.to_a
    @facets = finder.facets
    @current_page = finder.page
    @count = finder.count
    @num_results_shown = [@limit, @count].min
    @metadata_profile = MetadataProfile.default

    # If there are no results, get some search suggestions.
    if @count < 1 and params[:q].present?
      @suggestions = finder.suggestions
    end

    respond_to do |format|
      format.html do
        fresh_when(etag: @entities) if Rails.env.production?
      end
      format.atom do
        @updated = @entities.any? ?
                       @entities.map(&:updated_at).sort{ |d| d <=> d }.last : Time.now
      end
      format.js
      format.json do
        render json: {
            start: @start,
            numResults: @count,
            results: @entities.map { |entity|
              {
                  id: entity.repository_id,
                  url: url_for(entity)
              }
            }
        }
      end
    end
  end

  private

  def set_sanitized_params
    @permitted_params = params.permit(PERMITTED_PARAMS)
  end

end
