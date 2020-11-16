# frozen_string_literal: true

class KumquatMailer < ApplicationMailer

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
    mail(to: recipient, subject: "Hello from Kumquat")
  end

end
