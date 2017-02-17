require 'test_helper'

class MedusaClientTest < ActiveSupport::TestCase

  def setup
    @instance = MedusaClient.new
  end

  # class_of_uuid()

  test 'class_of_uuid() should return the correct class' do
    # file group
    uuid = '7afc3e80-b41b-0134-234d-0050569601ca-7'
    assert_equal MedusaFileGroup, @instance.class_of_uuid(uuid)

    # directory
    uuid = '7b1f3340-b41b-0134-234d-0050569601ca-8'
    assert_equal MedusaCfsDirectory, @instance.class_of_uuid(uuid)

    # file
    uuid = '6cc533c0-cebf-0134-238a-0050569601ca-3'
    assert_equal MedusaCfsFile, @instance.class_of_uuid(uuid)
  end

  test 'class_of_uuid() should return nil when given an invalid ID' do
    assert !@instance.class_of_uuid('cats')
  end

end
