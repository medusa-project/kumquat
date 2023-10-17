module Harvest

  ##
  # Supports harvesting into the Metadata Gateway using
  # [metaslurper](https://github.com/medusa-project/metaslurper).
  #
  # Provides RESTful endpoints similar to the public JSON endpoints, but
  # optimized for harvesting. This means that:
  #
  # 1. Authorization is bypassed (once authenticated using HTTP Basic), so
  #    unpublished Items are omitted, but IP-restricted ones are not;
  # 2. Certain entity attributes that are irrelevant to the harvester are
  #    excluded;
  # 3. The JSON representations are constructed to reduce the number of HTTP
  #    requests needed; for example, Binary info is embedded in Item
  #    representations.
  #
  class AbstractHarvestController < ActionController::Base

    protect_from_forgery with: :null_session

    layout false

    # N.B.: these must be listed in order of most generic to most specific.
    rescue_from StandardError, with: :rescue_internal_server_error

    before_action :authorize_user
    skip_before_action :verify_authenticity_token

    DEFAULT_RESULTS_LIMIT = 100
    MAX_RESULTS_LIMIT     = 1000

    protected

    ##
    # Authenticates a user via HTTP Basic and authorizes by IP address.
    #
    def authorize_user
      authenticate_or_request_with_http_basic do |username, secret|
        user = User.find_by_username(username)
        if user
          return user.api_key == secret
        end
      end
      false
    end

    def enforce_json_content_type
      if request.content_type != 'application/json'
        render plain: 'Invalid content type.', status: :unsupported_media_type
        return false
      end
      true
    end

    def rescue_internal_server_error(exception)
      @message = KumquatMailer.error_body(exception,
                                          url_path:  request.path,
                                          url_query: request.query_string)
      Rails.logger.error(@message)

      unless Rails.env.development?
        KumquatMailer.error(@message).deliver_now
      end

      respond_to do |format|
        format.html do
          render "errors/internal_server_error",
                 status: :internal_server_error,
                 content_type: "text/html"
        end
        format.all do
          render plain: "500 Internal Server Error",
                 status: :internal_server_error,
                 content_type: "text/plain"
        end
      end
    end

  end

end
