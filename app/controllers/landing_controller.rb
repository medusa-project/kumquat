class LandingController < WebsiteController

  IMAGE_MEDIA_TYPES = %w(image/jp2 image/jpeg image/png image/tiff)

  ##
  # Responds to GET /
  #
  def index
    # Get a random image item to show.
    finder = ItemFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        include_children(true).
        media_types(IMAGE_MEDIA_TYPES).
        sort(:random).
        limit(1)
    @random_item = finder.to_a.first

    # Get DLS collections
    @dls_collections = Collection.solr.
        where(Collection::SolrFields::ACCESS_SYSTEMS => 'Medusa Digital Library').
        where(Collection::SolrFields::PUBLISHED_IN_DLS => true).
        limit(100)

    role_keys = request_roles.map(&:key)
    if role_keys.any?
      # Include documents that have allowed roles matching one of the user
      # roles, or that have no effective allowed roles.
      @dls_collections = @dls_collections.
          where("(#{Collection::SolrFields::ALLOWED_ROLES}:(#{role_keys.join(' ')}) "\
          "OR (*:* -#{Collection::SolrFields::ALLOWED_ROLES}:[* TO *]))")
      # Exclude documents that have denied roles matching one of the user
      # roles.
      @dls_collections = @dls_collections.
          where("-#{Collection::SolrFields::DENIED_ROLES}:(#{role_keys.join(' ')})")
    else
      @dls_collections = @dls_collections.where("*:* -#{Collection::SolrFields::ALLOWED_ROLES}:[* TO *]")
    end

    fresh_when(etag: @dls_collections) if Rails.env.production?
  end

end
