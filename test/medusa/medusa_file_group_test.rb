require 'test_helper'

class MedusaFileGroupTest < ActiveSupport::TestCase

  def setup
    @fg = medusa_file_groups(:one)
  end

  # with_uuid()

  test 'with_uuid() should return an instance when given a UUID' do
    file = MedusaFileGroup.with_uuid(@fg.uuid)
    assert_equal @fg.title, file.title
  end

  test 'with_uuid() should cache returned instances' do
    MedusaFileGroup.destroy_all
    assert_nil MedusaFileGroup.find_by_uuid(@fg.uuid)
    MedusaFileGroup.with_uuid(@fg.uuid)
    assert_not_nil MedusaFileGroup.find_by_uuid(@fg.uuid)
  end

  # url()

  test 'url should return the correct url' do
    assert_equal(Configuration.instance.medusa_url.chomp('/') +
                     '/uuids/' + @fg.uuid,
                 @fg.url)
  end

end
