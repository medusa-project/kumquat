require 'test_helper'

class ElementTest < ActiveSupport::TestCase

  test 'dc_name should return the correct name' do
    e = Element.new
    e.name = 'spatialCoverage'
    assert_equal 'coverage', e.dc_name
  end

  test 'dcterms_name should return the correct name' do
    e = Element.new
    e.dcterms_name = 'spatialCoverage'
    assert_equal 'spatial', e.dcterms_name
  end

end
