##
# Handles cross-entity "global" searching and harvesting.
#
class SearchController < WebsiteController

  PERMITTED_PARAMS = [:_, :collection_id, { fq: [] }, :q, :sort, :start, :utf8]

  before_action :set_sanitized_params, only: :search

  ##
  # Used exclusively for harvesting by
  # [metaslurper](https://github.com/medusa-project/metaslurper). Returns only
  # JSON.
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
        # exclude all variants except File. (Only child items have these variants.)
        exclude_item_variants(*Item::Variants::all.reject{ |v| v == Item::Variants::FILE }).
        include_only_native_collections(true).
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
