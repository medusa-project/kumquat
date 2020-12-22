class HealthController < ApplicationController

  ##
  # Responds to `GET /health`
  #
  def index
    # Touch the database... except in demo, where the database is running in
    # Aurora and we can save money by letting it go idle.
    Collection.count unless Rails.env.demo?

    # touch Elasticsearch
    Item.search.aggregations(false).limit(0).count
  rescue => e
    render plain: "RED: #{e}", status: :internal_server_error
  else
    render plain: 'GREEN'
  end

end
