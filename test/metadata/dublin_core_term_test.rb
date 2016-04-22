require 'test_helper'

class DublinCoreTermTest < ActiveSupport::TestCase

  test 'all should return all elements' do
    assert_equal 55, DublinCoreTerm.all.length
  end

  test 'label_for should return a label' do
    assert_equal 'Accrual Policy', DublinCoreTerm.label_for('accrualPolicy')
  end

end
