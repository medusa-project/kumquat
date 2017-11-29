require 'test_helper'

class StringUtilsTest < ActiveSupport::TestCase

  test 'rot18() works' do
    str = 'set:8132f520-e3fb-012f-c5b6-0019b9e633c5-f|start:100|metadataPrefix:oai_dc'
    expected = 'frg:3687s075-r8so-567s-p0o1-5564o4r188p0-s|fgneg:655|zrgnqngnCersvk:bnv_qp'
    assert_equal(expected, StringUtils.rot18(str))
  end

end
