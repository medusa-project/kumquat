class LandingController < WebsiteController

  ##
  # Responds to GET /
  #
  def index
    # Get a random image item to show
    image_media_types = %w(image/jp2 image/jpeg image/png image/tiff).join(' OR ')
    items = Item.solr.
        where(Item::SolrFields::PUBLISHED => true).
        where(Item::SolrFields::COLLECTION_PUBLISHED => true).
        filter(Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE => "(#{image_media_types})").
        facet(false).order(:random)

    role_keys = request_roles.map(&:key)
    if role_keys.any?
      # Include documents that have allowed roles matching one of the user
      # roles, or that have no effective allowed roles.
      items = items.where("(#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:(#{role_keys.join(' ')}) "\
          "OR (*:* -#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:[* TO *])")
      # Exclude documents that have denied roles matching one of the user
      # roles.
      items = items.where("-#{Item::SolrFields::EFFECTIVE_DENIED_ROLES}:(#{role_keys.join(' ')}))")
    else
      items = items.where("*:* -#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:[* TO *]")
    end

    @random_item = items.limit(1).first

=begin TODO: enable this
    finder = ItemFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        include_children(true).
        filter(Item::SolrFields::PUBLISHED => true).
        filter(Item::SolrFields::COLLECTION_PUBLISHED => true).
        filter(Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE => "(#{image_media_types})").
        sort(:random).
        limit(1)
    @random_item = finder.to_a.first
=end

    # Get DLS collections
    @dls_collections = Collection.solr.
        where(Collection::SolrFields::ACCESS_SYSTEMS => 'Medusa Digital Library').
        where(Collection::SolrFields::PUBLISHED_IN_DLS => true).
        limit(100)

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
