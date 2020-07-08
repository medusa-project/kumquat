# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "University of Illinois at Urbana-Champaign Library Digital Collections <#{::Configuration.instance.mail[:from]}>"
  layout "mailer"
end
