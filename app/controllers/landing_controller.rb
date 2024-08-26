class LandingController < WebsiteController

  ##
  # Responds to GET /
  #
  #
  def contact
    if !check_captcha
      Rails.logger.debug "CAPTCHA validation failed."
      render plain: "Incorrect math question response.", status: :bad_request
      return
    elsif params[:comment]&.blank?
      render plain: "Please enter a comment.", status: :bad_request
      return 
    end

    feedback_email = Setting.string(Setting::Keys::ADMINISTRATOR_EMAIL)
    begin 
      KumquatMailer.contact_form_message(page_url: params[:page_url],
                                          from_name: params[:name],
                                          from_email: params[:email],
                                          comment:    params[:comment],
                                          to_email:  feedback_email).deliver_later
    rescue => e
      LOGGER.error("#{e}")
        render plain: "An error occurred on the server.", status: :internal_server_error 
    else
        render plain: "OK"
    end
  end 

  def index
    authorize(:landing)
    @gateway_item_count = Rails.cache.fetch('gateway.item_count',
                                            expires_in: 12.hours) do
      begin
        GatewayClient.instance.num_items
      rescue
        # The gateway is probably down. This is a problem that is better dealt
        # with elsewhere; failing here should not fail the request.
        nil
      end
    end
  end

end
