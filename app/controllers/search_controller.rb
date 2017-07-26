##
# Handles cross-entity "global" searching.
#
class SearchController < WebsiteController

  ##
  # Responds to GET /search
  #
  def search
    @start = params[:start].to_i
    @limit = Option::integer(Option::Keys::RESULTS_PER_PAGE)

    # EntityFinder will search across entity classes and return both Items and
    # Collections.
    finder = EntityFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        # exclude all variants except File
        exclude_item_variants(Item::Variants::all.reject{ |v| v == Item::Variants::FILE }).
        only_described(true).
        query(params[:q]).
        filter_queries(params[:fq]).
        sort(params[:sort]).
        start(@start).
        limit(@limit)
    @entities = finder.to_a
    @current_page = finder.page
    @count = finder.count
    @num_results_shown = [@limit, @count].min
    @metadata_profile = MetadataProfile.default

    # If there are no results, get some search suggestions.
    if @count < 1 and params[:q].present?
      @suggestions = finder.suggestions
    end

    respond_to do |format|
      format.atom do
        @updated = @entities.any? ?
            @entities.map(&:updated_at).sort{ |d| d <=> d }.last : Time.now
      end
      format.html do
        fresh_when(etag: @entities) if Rails.env.production?
      end
      format.js
    end
  end

end
