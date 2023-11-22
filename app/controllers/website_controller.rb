##
# Base controller for all controllers related to the public website.
#
class WebsiteController < ApplicationController

  MAX_RESULT_WINDOW = 100
  MIN_RESULT_WINDOW = 10

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

  ##
  # @return [Collection,nil], Collection in the current context, or nil if
  #                           there is <> 1
  #
  def collection
    id = nil
    if controller_name == 'collections'
      id = params[:id]
    elsif controller_name == 'items'
      if params[:collection_id]
        id = params[:collection_id]
      elsif params[:id]
        item = Item.find_by_repository_id(params[:id])
        id   = item&.collection&.repository_id
      end
    end
    if id
      return Collection.find_by_repository_id(id)
    end
    nil
  end

  def enable_cors
    headers['Access-Control-Allow-Origin'] = '*'
  end

end
