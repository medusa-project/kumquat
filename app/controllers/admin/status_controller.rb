module Admin

  class StatusController < ControlPanelController

    JOB_WORKER_PIDFILE = File.join(Rails.root, 'tmp', 'pids', 'delayed_job.pid')

    ##
    # Responds to GET /admin/status/downloader.
    #
    def downloader_status
      client = MedusaDownloaderClient.new
      begin
        client.head
      rescue IOError
        render json: { status: 'offline' }
      else
        render json: { status: 'online' }
      end
    end

    ##
    # Responds to GET /admin/status
    #
    def index
    end

    ##
    # Responds to GET /admin/status/image-server.
    #
    def image_server_status
      config = ::Configuration.instance
      client = ImageServer.instance.client
      begin
        response = client.head(config.iiif_url)
        if response.status == 200
          render json: { status: 'online' }
        else
          render json: { status: 'offline' }
        end
      rescue
        render json: { status: 'offline' }
      end
    end

    ##
    # Responds to GET /admin/status/job-worker.
    #
    def job_worker_status
      if File.exists?(JOB_WORKER_PIDFILE)
        render json: { status: 'online', pid: job_worker_pid }
      else
        render json: { status: 'offline' }
      end
    end

    ##
    # Responds to GET /admin/status/search-server.
    #
    def search_server_status
      begin
        Solr.instance.get('select', params: { q: '*:*', start: 0, rows: 1 })
      rescue RSolr::Error::Http
        render json: { status: 'offline' }, status: 503
      else
        render json: { status: 'online' }
      end
    end

    private

    def job_worker_pid
      File.exists?(JOB_WORKER_PIDFILE) ?
          File.read(JOB_WORKER_PIDFILE).strip.to_i : nil
    end

  end

end
