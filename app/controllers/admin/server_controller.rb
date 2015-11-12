module Admin

  class ServerController < ControlPanelController

    def index
    end

    ##
    # Responds to GET /admin/server/image-server-status with either HTTP 200
    # or 503
    #
    def image_server_status
      http = HTTPClient.new
      begin
        response = http.get(PearTree::Application.peartree_config[:iiif_url])
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
    # Responds to PATCH /admin/server/reindex
    #
    def reindex
      args = {
          command: ReindexCommand,
          task_status_text: 'Reindex repository'
      }
      job_runner.run_later(CommandJob, args)

      flash['success'] = 'Reindexing in progress.'
      redirect_to :back
    end

    ##
    # Responds to GET /admin/server/search-server-status with either HTTP 200
    # or 503
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
