require 'test_helper'

class UrlUtilsTest < ActiveSupport::TestCase

  test 'parse_query returns an empty hash for URLs that have no query' do
    assert_empty UrlUtils.parse_query('http://example.org/')
    assert_empty UrlUtils.parse_query('http://example.org?')
  end

  test 'parse_query returns a hash for URLs that have a query' do
    result = UrlUtils.parse_query('http://example.org?key1=value1&key2=value2')
    assert_equal 'value1', result['key1']
    assert_equal 'value2', result['key2']

    result = UrlUtils.parse_query('http://example.org?key')
    assert_nil result['key']
  end

  test 'parse_query decodes the query' do
    result = UrlUtils.parse_query('http://example.org?key=%2Fvalue')
    assert_equal '/value', result['key']
  end

end
