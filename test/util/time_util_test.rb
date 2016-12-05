require 'test_helper'

class TimeUtilTest < ActiveSupport::TestCase

  test 'string_date_to_time with an unrecognizable argument should return nil' do
    assert_nil TimeUtil.string_date_to_time('cats')
  end

  test 'string_date_to_time should work with YYYY:MM:DD HH:MM:SS' do
    assert_equal Time.parse('1923-02-12 12:10:50Z'),
                 TimeUtil.string_date_to_time('1923:02:12 12:10:50')
  end

  test 'string_date_to_time should work with YYYY-MM-DD' do
    assert_equal Time.parse('1923-02-12 00:00:00Z'),
                 TimeUtil.string_date_to_time('1923-02-12')
  end

  test 'string_date_to_time should work with YYYY:MM:DD' do
    assert_equal Time.parse('1923-02-12 00:00:00Z'),
                 TimeUtil.string_date_to_time('1923:02:12')
  end

  test 'string_date_to_time should work with YYYY' do
    assert_equal Time.parse('1923-01-01 00:00:00Z'),
                 TimeUtil.string_date_to_time('1923')
  end

end
