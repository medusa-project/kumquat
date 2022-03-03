# frozen_string_literal: true

class KumquatMailer < ApplicationMailer

  # This address is not arbitrary;
  # see https://answers.uillinois.edu/illinois/page.php?id=47888
  NO_REPLY_ADDRESS = "no-reply@illinois.edu"

  ##
  # @param exception [Exception]
  # @param url [String]          Request URL.
  # @param url_path [String]     Request URL path.
  # @param url_query [String]    Request URL query string.
  # @param user [User]           Current user.
  # @return [String]
  #
  def self.error_body(exception,
                      url:       nil,
                      url_path:  nil,
                      url_query: nil,
                      user:      nil)
    io = StringIO.new
    io << "Error\n"
    io << "Class: #{exception.class}\n"
    io << "Message: #{exception.message}\n"
    io << "URL: #{url}\n" if url
    io << "    Path: #{url_path}\n" if url_path
    io << "    Query: #{url_query}\n" if url_query
    io << "User: #{user.username}\n" if user
    io << "Time: #{Time.now.iso8601}\n"
    io << "Stack Trace:\n"
    exception.backtrace.each do |line|
      io << line
      io << "\n"
    end
    io.string
  end

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
  # Sends an email about new items in the collection associated with the given
  # [Watch] to its associated user.
  #
  # @param watch [Watch]
  # @param tsv [String]
  # @param after [Time]
  # @param before [Time]
  #
  def new_items(watch, tsv, after, before)
    @after   = after.strftime('%Y-%m-%d')
    @before  = before.strftime('%Y-%m-%d')
    filename = "items-#{@after}-#{@before}"
    attachments[filename] = tsv
    mail(to:      watch.email || watch.user.email,
         subject: "#{subject_prefix} New items in #{watch.collection}")
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
