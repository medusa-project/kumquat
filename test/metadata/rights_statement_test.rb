require 'test_helper'

class RightsStatementTest < ActiveSupport::TestCase

  # all_statements()

  test 'all_statements() should return all statements' do
    assert_equal 12, RightsStatement.all_statements.length
  end

  # for_uri()

  test 'for_uri() should return nil for a bogus URI' do
    assert_nil RightsStatement.for_uri('http://example.org/bogus')
  end

  test 'for_uri() should return a statement for a valid URI' do
    uri = 'http://rightsstatements.org/vocab/InC/1.0/'
    st = RightsStatement.for_uri(uri)
    assert_equal 'In Copyright', st.name
    assert_equal 'rightsstatements.org/InC.dark-white-interior.svg', st.image
    assert_equal 'http://rightsstatements.org/page/InC/1.0/', st.info_uri
    assert_equal uri, st.uri
  end

end
