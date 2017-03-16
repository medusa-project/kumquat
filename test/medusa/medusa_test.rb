require 'test_helper'

class MedusaTest < ActiveSupport::TestCase

  # url()

  test 'url() should return the correct URL' do
    uuid = 'cats'
    expected = sprintf('%s/uuids/%s.json',
                       Configuration.instance.medusa_url.chomp('/'), uuid)
    assert_equal expected, Medusa.url(uuid)
  end

end
