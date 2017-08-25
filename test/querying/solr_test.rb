require 'test_helper'

class SolrTest < ActiveSupport::TestCase

  test 'escape() works' do
    query = 'The quick brown fox jumped over the lazy dog + - && || ! ( ) { } [ ] ^ " ~ * ? : \\'
    expected = 'The quick brown fox jumped over the lazy dog \+ \- \&& \|| \!   \{ \} \[ \] \^ \" \~ \* \? \: \\\\'
    assert_equal expected, Solr.escape(query)
  end

end
