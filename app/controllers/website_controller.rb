##
# Base controller for all controllers related to the public website.
#
class WebsiteController < ApplicationController

  MAX_RESULT_WINDOW = 100
  MIN_RESULT_WINDOW = 10

  def contact
    if !check_captcha
      Rails.logger.debug "CAPTCHA validation failed."
      redirect_to request.referer || root_path, notice: "FAILED to send. Incorrect math question response. Please try again."
      # render plain: "Incorrect math question response.", status: :bad_request
      return
    elsif params[:comment]&.blank?
      redirect_to request.referer || root_path, alert: "Enter comment."
      # render plain: "Please enter a comment.", status: :bad_request
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
      redirect_to request.referer || root_path, alert: "An error occurred on the server."
        # render plain: "An error occurred on the server.", status: :internal_server_error 
    else
      redirect_to request.referer || root_path, notice: "Thank you for your feedback."  
      # render plain: "OK"
    end
  end 
  
  protected

  ##
  # Checks whether the client has passed a CAPTCHA test. Three form fields are
  # checked:
  #
  # 1. A hash of the salted correct answer to a question, e.g. "what's 5 + 3?"
  # 2. The answer to the question above, provided by the client, whose salted
  #    hash is expected to match #1
  # 3. Another irrelevant field that is hidden via CSS and expected to remain
  #    unfilled (the "honeypot technique")
  #
  # The form data is expected to arrive via XHR. In the handler, check the
  # return value and return immediately if it is `false`.
  #
  # This method works in conjunction with {ApplicationHelper#captcha} and the
  # `Application.CaptchaProtectedDownload()` JavaScript function.
  #
  # @return [Boolean] If `false`, the check failed and the caller should return
  #                   immediately.
  #
  def check_captcha
    puts "check captcha called"
    email = params[:honey_email]
    success = email.blank?
    Rails.logger.debug "Honeypot email check: #{success}"
    if success 
      answer_hash = Digest::MD5.hexdigest("#{params[:answer]}#{ApplicationHelper::CAPTCHA_SALT}")
      expected_hash = params[:correct_answer_hash]
      success = (answer_hash == expected_hash)
      Rails.logger.debug "CAPTCHA answer check: #{success}"
    end
    success 
  end

  def check_item_captcha
    success = true

    # Check the honeypot
    email = params[:email]
    if email.present?
      success = false
      message = "Invalid response."
    end
    if success
      # Check the answer
      answer_hash   = Digest::MD5.hexdigest("#{params[:answer]}#{ApplicationHelper::CAPTCHA_SALT}")
      expected_hash = params[:correct_answer_hash]
      if answer_hash != expected_hash
        success = false
        message = "Incorrect response. Please try again."
      end
    end
    unless success
      response.status                       = :bad_request
      response.headers['X-Kumquat-Result']  = "error"
      response.headers['X-Kumquat-Message'] = message
      render plain: nil, content_type: request.format
      return false
    end
    true
  end

  def enable_cors
    headers['Access-Control-Allow-Origin'] = '*'
  end

end
