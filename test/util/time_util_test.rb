require 'test_helper'

class TimeUtilTest < ActiveSupport::TestCase

  # hms_to_seconds()

  test 'hms_to_seconds with a nil argument should raise an ArgumentError' do
    assert_raises ArgumentError do
      TimeUtil.hms_to_seconds(nil)
    end
  end

  test 'hms_to_seconds with an unrecognizable argument should raise an ArgumentError' do
    assert_raises ArgumentError do
      TimeUtil.hms_to_seconds('23:12')
    end
  end

  test 'hms_to_seconds works with HH:MM:SS' do
    assert_equal 1 * 60 * 60 + 10 * 60 + 10, TimeUtil.hms_to_seconds('01:10:10')
  end

  test 'hms_to_seconds works with HH:MM:SS.MS' do
    assert_equal 1 * 60 * 60 + 10 * 60 + 10.10,
                 TimeUtil.hms_to_seconds('01:10:10.10')
  end

  # string_date_to_time()

  test 'string_date_to_time with a nil argument should return nil' do
    assert_nil TimeUtil.string_date_to_time(nil)
  end

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

  test 'string_date_to_time should work with [YYYY]' do
    assert_equal Time.parse('1923-01-01 00:00:00Z'),
                 TimeUtil.string_date_to_time('[1923]')
  end

  test 'string_date_to_time should work with [YYYY?]' do
    assert_equal Time.parse('1923-01-01 00:00:00Z'),
                 TimeUtil.string_date_to_time('[1923?]')
  end

  test 'string_date_to_time should work with ISO 8601' do
    assert_equal Time.parse('1923-02-12 06:00:00Z'),
                 TimeUtil.string_date_to_time('1923-02-12 00:00:00Z')
  end

end
