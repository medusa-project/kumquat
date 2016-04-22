require 'test_helper'

class DublinCoreElementTest < ActiveSupport::TestCase

  test 'all should return all elements' do
    assert_equal 15, DublinCoreElement.all.length
  end

  test 'label_for should return a label' do
    assert_equal 'Creator', DublinCoreElement.label_for('creator')
  end

end
