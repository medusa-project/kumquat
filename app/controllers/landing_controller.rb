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

    # Get some counts for the statistics table
    @num_all_items = Item.solr.
        where(Item::SolrFields::PUBLISHED => true).
        where(Item::SolrFields::COLLECTION_PUBLISHED => true).count
    @num_top_level_items = Item.solr.
        where(Item::SolrFields::PUBLISHED => true).
        where(Item::SolrFields::COLLECTION_PUBLISHED => true).
        where(Item::SolrFields::PARENT_ITEM => :null).count

    @num_audio_items = Item.solr.
        where(Item::SolrFields::PUBLISHED => true).
        where(Item::SolrFields::COLLECTION_PUBLISHED => true).
        where("#{Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE}:audio/* "\
        "OR #{Item::SolrFields::PRESERVATION_MASTER_MEDIA_TYPE}:audio/*").count

    doc_media_types = %w(application/pdf text/plain).join(' OR ')
    @num_document_items = Item.solr.
        where(Item::SolrFields::PUBLISHED => true).
        where(Item::SolrFields::COLLECTION_PUBLISHED => true).
        where("#{Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE}:(#{doc_media_types}) "\
        "OR #{Item::SolrFields::PRESERVATION_MASTER_MEDIA_TYPE}:(#{doc_media_types})").count

    @num_image_items = Item.solr.
        where(Item::SolrFields::PUBLISHED => true).
        where(Item::SolrFields::COLLECTION_PUBLISHED => true).
        where("#{Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE}:image/* "\
        "OR #{Item::SolrFields::PRESERVATION_MASTER_MEDIA_TYPE}:image/*").count

    @num_video_items = Item.solr.
        where(Item::SolrFields::PUBLISHED => true).
        where(Item::SolrFields::COLLECTION_PUBLISHED => true).
        where("#{Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE}:video/* "\
        "OR #{Item::SolrFields::PRESERVATION_MASTER_MEDIA_TYPE}:video/*").count

    fresh_when(etag: @num_all_items) if Rails.env.production?
  end

end
