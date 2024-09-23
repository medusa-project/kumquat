require 'test_helper'

class KumquatMailerTest < ActionMailer::TestCase

  tests KumquatMailer

  # error_body()

  test "error_body() returns a string" do
    begin
      raise "Something happened"
    rescue => e
      string = KumquatMailer.error_body(e)
      assert string.starts_with?("Error\n")
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

  test "contact_form_message() sends user feedback/comment" do 
    from_email = "example@email.com"
    page_url = "http://example.com/contact"
    to_email = Setting.string(Setting::Keys::ADMINISTRATOR_EMAIL)
    email_message = KumquatMailer.contact_form_message(
      from_email: from_email, 
      from_name: "visitor", 
      page_url: page_url, 
      comment: "Feedback."
    )

    assert_equal [to_email], email_message.to
    assert_equal [from_email], email_message.from
  end

  # new_items()

  test 'new_items() sends the expected email to the user associated with the
  watch' do
    collection = collections(:compound_object)
    user       = users(:medusa_admin)
    watch      = Watch.create!(collection: collection,
                               user:       user)
    tsv        = 'pretend this is some TSV'
    after      = Time.new(2021, 6, 28)
    before     = Time.new(2021, 6, 29)
    email      = KumquatMailer.new_items(watch, tsv, after, before).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    config = ::Configuration.instance
    assert_equal [config.mail[:reply_to]], email.reply_to
    assert_equal [user.email], email.to
    assert_equal "[TEST: Kumquat] New items in #{collection}", email.subject
    assert_equal render_template("new_items.txt"), email.text_part.body.raw_source
    assert_equal render_template("new_items.html"), email.html_part.body.raw_source
  end

  test 'new_items() sends the expected email to the email associated with the
  watch' do
    collection = collections(:compound_object)
    email_addr = 'somebody@example.org'
    watch      = Watch.create!(collection: collection,
                               email:      email_addr)
    tsv        = 'pretend this is some TSV'
    after      = Time.new(2021, 6, 28)
    before     = Time.new(2021, 6, 29)
    email      = KumquatMailer.new_items(watch, tsv, after, before).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    config = ::Configuration.instance
    assert_equal [config.mail[:reply_to]], email.reply_to
    assert_equal [email_addr], email.to
    assert_equal "[TEST: Kumquat] New items in #{collection}", email.subject
    assert_equal render_template("new_items.txt"), email.text_part.body.raw_source
    assert_equal render_template("new_items.html"), email.html_part.body.raw_source
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
