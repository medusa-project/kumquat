require 'test_helper'

class FacetTermTest < ActiveSupport::TestCase

  setup do
    @instance = FacetTerm.new
    @instance.count = 5
    @instance.name  = 'something'
    @instance.label = 'Something'
    @instance.facet       = Facet.new
    @instance.facet.field = 'subject'
    @instance.facet.name  = 'Subject'
  end

  test 'added_to_params works' do
    expected = ActionController::Parameters.new
    expected[:fq] = ['subject:something']

    actual = ActionController::Parameters.new
    actual = @instance.added_to_params(actual)
    assert_equal expected, actual
  end

  test 'query works' do
    assert_equal 'subject:something', @instance.query
  end

  test 'removed_from_params works' do
    expected = ActionController::Parameters.new
    expected[:fq] = []

    actual = ActionController::Parameters.new
    actual[:fq] = ['subject:something']
    actual = @instance.removed_from_params(actual)
    assert_equal expected, actual
  end

end
