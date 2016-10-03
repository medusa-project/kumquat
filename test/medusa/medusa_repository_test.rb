require 'test_helper'

class MedusaRepositoryTest < ActiveSupport::TestCase

  def setup
    @repo = MedusaRepository.new
    @repo.id = 32
  end

  # contact_email()

  test 'contact_email() should return the email' do
    assert_equal 'jmj@illinois.edu', @repo.contact_email
  end

  # email()

  test 'email() should return the email' do
    assert_equal 'jmj@uiuc.edu', @repo.email
  end

  # title()

  test 'title() should return the title' do
    assert_equal 'Map and Geography Library', @repo.title
  end

  # url()

  test 'url() should return the URL' do
    assert_equal Configuration.instance.medusa_url + 'repositories/32',
                 @repo.url
  end

end
