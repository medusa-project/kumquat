module Admin

  class StatusController < ControlPanelController

    ##
    # Responds to GET /admin/status/downloader with either HTTP 200 or 503.
    #
    def downloader_status
      client = MedusaDownloaderClient.new
      begin
        client.head
      rescue IOError
        render text: 'offline', status: 503
      else
        render text: 'online'
      end
    end

    def index
    end

    ##
    # Responds to GET /admin/status/image-server with either HTTP 200
    # or 503.
    #
    def image_server_status
      config = ::Configuration.instance
      client = ImageServer.instance.client
      begin
        response = client.head(config.iiif_url)
        if response.status == 200
          render text: 'online'
        else
          render text: 'offline', status: 503
        end
      rescue
        render text: 'offline', status: 503
      end
    end

    ##
    # Responds to GET /admin/status/search-server with either HTTP 200
    # or 503.
    #
    def search_server_status
      solr = Solr.instance
      begin
        solr.get('select', params: { q: '*:*', start: 0, rows: 1 })
      rescue RSolr::Error::Http
        render text: 'offline', status: 503
      else
        render text: 'online'
      end
    end

  end

end
