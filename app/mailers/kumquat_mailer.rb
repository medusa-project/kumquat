# frozen_string_literal: true

class KumquatMailer < ApplicationMailer

  # This address is not arbitrary;
  # see https://answers.uillinois.edu/illinois/page.php?id=47888
  NO_REPLY_ADDRESS = "no-reply@illinois.edu"

  ##
  # @oaram error_text [String]
  #
  def error(error_text)
    @error_text = error_text
    mail(reply_to: NO_REPLY_ADDRESS,
         to:       ::Configuration.instance.admin_email_list,
         subject:  "#{subject_prefix} System Error")
  end

  ##
  # @param item [Item]
  # @param netid [String]
  #
  def restricted_item_available(item, netid)
    @item  = item
    @netid = netid
    mail(to: "#{netid}@illinois.edu",
         subject: "Your requested item is available")
  end

  ##
  # Used to test email delivery. See also the `mail:test` rake task.
  #
  def test(recipient)
    mail(to: recipient, subject: "#{subject_prefix} Hello from Kumquat")
  end


  private

  def subject_prefix
    "[#{Rails.env.to_s.upcase}: Kumquat]"
  end

end
