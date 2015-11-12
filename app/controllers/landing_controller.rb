class LandingController < WebsiteController

  ##
  # Responds to GET /
  #
  def index
    # Get a random image item to show
    media_types = %w(image/jp2 image/jpeg image/png image/tiff).join(' OR ')
    @random_item = Item.where("(#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:(#{media_types}) OR "\
    "#{Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE}:(#{media_types}))").
        facet(false).order(:random).limit(1).first
  end

end
