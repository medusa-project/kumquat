module Api

  class ApiController < ApplicationController

    layout false

    before_action :authorize_user
    skip_before_action :verify_authenticity_token

    DEFAULT_RESULTS_LIMIT = 100
    MAX_RESULTS_LIMIT = 1000

    protected

    ##
    # Authenticates a user via HTTP Basic and authorizes by IP address.
    #
    def authorize_user
      authenticate_or_request_with_http_basic do |username, secret|
        config = ::Configuration.instance
        if username == config.api_user and secret == config.api_secret
          return config.api_ips.select{ |ip| request.remote_ip.start_with?(ip) }.any?
        end
      end
      false
    end

    def enforce_xml_content_type
      if request.content_type != 'application/xml'
        render text: 'Invalid content type.', status: :unsupported_media_type
        return false
      end
      true
    end

  end

end
