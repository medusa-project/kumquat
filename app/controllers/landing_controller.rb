class LandingController < WebsiteController

  ##
  # Responds to GET /
  #
  def index
    # Get a random image item to show
    image_media_types = %w(image/jp2 image/jpeg image/png image/tiff).join(' OR ')
    @random_item = Item.solr.
        where(Item::SolrFields::PUBLISHED => true).
        where(Item::SolrFields::COLLECTION_PUBLISHED => true).
        filter(Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE => "(#{image_media_types})").
        facet(false).order(:random).limit(1).first

    # Get DLS collections
    @dls_collections = Collection.solr.
        where(Collection::SolrFields::ACCESS_SYSTEMS => 'Medusa Digital Library').
        where(Collection::SolrFields::PUBLISHED_IN_DLS => true).
        limit(100)

    fresh_when(etag: @dls_collections) if Rails.env.production?
  end

end
