require 'test_helper'

class MedusaClientTest < ActiveSupport::TestCase

  def setup
    @instance = MedusaClient.instance
  end

  # class_of_uuid()

  test 'class_of_uuid() should return the correct class' do
    # file group
    uuid = '5881d456-6dbe-90f1-ac81-7e0bf53e9c84'
    assert_equal MedusaFileGroup, @instance.class_of_uuid(uuid)

    # directory
    uuid = '1b760655-c504-7fce-f171-76e4234844da'
    assert_equal MedusaCfsDirectory, @instance.class_of_uuid(uuid)

    # file
    uuid = '39582239-4307-1cc6-c9c6-074516fd7635'
    assert_equal MedusaCfsFile, @instance.class_of_uuid(uuid)
  end

  test 'class_of_uuid() should return nil when given an invalid ID' do
    assert !@instance.class_of_uuid('cats')
  end

end
