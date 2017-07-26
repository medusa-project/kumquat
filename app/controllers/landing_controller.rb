class LandingController < WebsiteController

  COLLECTIONS_LIMIT = 20

  ##
  # Responds to GET /
  #
  def index
    # Get DLS collections.
    finder = CollectionFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        filter_queries(Collection::SolrFields::ACCESS_SYSTEMS => 'Medusa Digital Library').
        limit(COLLECTIONS_LIMIT)
    @dls_collections = finder.to_a

    # Get a count of all published collections.
    @num_all_collections = Collection.all.where(public_in_medusa: true,
                                                published_in_dls: true).count

    fresh_when(etag: @dls_collections) if Rails.env.production?
  end

end
