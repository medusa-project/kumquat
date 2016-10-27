class LandingController < WebsiteController

  IMAGE_MEDIA_TYPES = %w(image/jp2 image/jpeg image/png image/tiff)

  ##
  # Responds to GET /
  #
  def index
    # Get a random collection to show.
    finder = CollectionFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        filter_queries(Collection::SolrFields::ACCESS_SYSTEMS => 'Medusa Digital Library').
        order(:random).
        limit(1)
    @random_collection = finder.to_a.first

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
