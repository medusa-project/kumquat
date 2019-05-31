module Admin

  class TestController < ControlPanelController

    ##
    # Renders a view containing a random sampling of thumbnails served by the
    # image server without caching. This is useful for testing the image
    # server.
    #
    # Responds to GET /admin/test-images
    #
    def index
      size_limit = 10000000
      @images = Binary.
          where('byte_size < ?', size_limit).
          where(media_category: Binary::MediaCategory::IMAGE).
          order(Arel.sql('RANDOM()')).
          limit(20)

      if params[:media_type].present?
        @images = @images.where(media_type: params[:media_type])
      end
    end

  end

end
