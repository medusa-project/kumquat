class LandingController < WebsiteController

  COLLECTIONS_LIMIT = 20

  ##
  # Responds to GET /
  #
  def index
    # Get DLS collections.
    finder = CollectionFinder.new.
        user_roles(request_roles).
        facet_filters(Collection::IndexFields::ACCESS_SYSTEMS => 'Medusa Digital Library').
        order(Collection::IndexFields::TITLE).
        limit(COLLECTIONS_LIMIT)
    @dls_collections = finder.to_a

    # Get a count of all published collections.
    finder = CollectionFinder.new.user_roles(request_roles)
    @num_all_collections = finder.count

    fresh_when(etag: @dls_collections) if Rails.env.production?
  end

end
