# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "Illinois Digital Library <#{::Configuration.instance.mail[:from]}>"
  layout "mailer"
end
