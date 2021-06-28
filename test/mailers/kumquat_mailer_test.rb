require 'test_helper'

class KumquatMailerTest < ActionMailer::TestCase

  tests KumquatMailer

  # error_body()

  test "error_body() returns a string" do
    begin
      raise "Something happened"
    rescue => e
      string = KumquatMailer.error_body(e)
      assert string.starts_with?("Error:\n")
    end
  end

  # error()

  test "error() sends the expected email" do
    email = KumquatMailer.error("Something broke").deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    config = ::Configuration.instance
    assert_equal [KumquatMailer::NO_REPLY_ADDRESS], email.reply_to
    assert_equal config.admin_email_list, email.to
    assert_equal "[TEST: Kumquat] System Error", email.subject
    assert_equal "Something broke\r\n\r\n", email.body.raw_source
  end

  # test()

  test "test() sends the expected email" do
    recipient = "user@example.edu"
    email = KumquatMailer.test(recipient).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [Configuration.instance.mail[:from]], email.from
    assert_equal [recipient], email.to
    assert_equal "[TEST: Kumquat] Hello from Kumquat", email.subject

    assert_equal render_template("test.txt"), email.text_part.body.raw_source
    assert_equal render_template("test.html"), email.html_part.body.raw_source
  end


  private

  def render_template(fixture_name, vars = {})
    text = read_fixture(fixture_name).join
    vars.each do |k, v|
      text.gsub!("{{{#{k}}}}", v)
    end
    text
  end

end
