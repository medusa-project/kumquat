module Admin

  class StatusController < ControlPanelController

    ##
    # Responds to GET /admin/status
    #
    def index
      respond_to do |format|
        format.html
        format.json do
          struct = [
              application_status,
              downloader_status,
              image_server_status,
              elasticsearch_status
          ]
          struct += job_worker_status
          render json: struct
        end
      end
    end

    private

    def application_status
      { service: 'Application', status: 'online' }
    end

    def downloader_status
      struct = { service: 'Downloader' }
      client = MedusaDownloaderClient.new
      begin
        client.head
      rescue IOError
        struct[:status] = 'offline'
      else
        struct[:status] = 'online'
      end
      struct
    end

    def elasticsearch_status
      index = ElasticsearchIndex.current_index(Collection)
      {
          service: 'Elasticsearch',
          status: index.exists? ? 'online' : 'offline'
      }
    end

    def image_server_status
      struct = { service: 'Image Server' }
      config = ::Configuration.instance
      client = ImageServer.instance.client
      begin
        response = client.head(config.iiif_url)
        if response.status == 200
          struct[:status] = 'online'
        else
          struct[:status] = 'offline'
        end
      rescue
        struct[:status] = 'offline'
      end
      struct
    end

    def job_worker_status
      Job.worker_pids.map do |pid|
        { service: 'Job Worker', status: 'online', pid: pid }
      end
    end

  end

end
