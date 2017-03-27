class LandingController < WebsiteController

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
        limit(100)
    @dls_collections = finder.to_a

    fresh_when(etag: @dls_collections) if Rails.env.production?
  end

end
