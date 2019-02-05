require 'test_helper'

class TimeUtilTest < ActiveSupport::TestCase

  # eta()

  test 'eta works' do
    expected = 1.year.from_now
    actual = TimeUtil.eta(5.hours.ago, 0.0)
    assert actual - expected < 1

    expected = 5.hours.from_now
    actual = TimeUtil.eta(5.hours.ago, 0.5)
    assert actual - expected < 1

    expected = 6.hours.from_now
    actual = TimeUtil.eta(2.hours.ago, 0.25)
    assert actual - expected < 1

    expected = 2.hours.from_now
    actual = TimeUtil.eta(6.hours.ago, 0.75)
    assert actual - expected < 1

    expected = Time.now.utc
    actual = TimeUtil.eta(6.hours.ago, 1.0)
    assert actual - expected < 1
  end

  # hms_to_seconds()

  test 'hms_to_seconds with a nil argument raises an ArgumentError' do
    assert_raises ArgumentError do
      TimeUtil.hms_to_seconds(nil)
    end
  end

  test 'hms_to_seconds with an unrecognizable argument raises an ArgumentError' do
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

  # seconds_to_hms()

  test 'seconds_to_hms with a nil argument should raise an ArgumentError' do
    assert_raises ArgumentError do
      TimeUtil.seconds_to_hms(nil)
    end
  end

  test 'seconds_to_hms with an unrecognizable argument should raise an ArgumentError' do
    assert_raises ArgumentError do
      TimeUtil.seconds_to_hms('23:12')
    end
  end

  test 'seconds_to_hms works' do
    assert_equal '00:00:30', TimeUtil.seconds_to_hms(30)
    assert_equal '00:05:00', TimeUtil.seconds_to_hms(300)
    assert_equal '01:15:02', TimeUtil.seconds_to_hms(4502)
  end

  # parse_date()

  test 'parse_date with a nil argument returns nil' do
    assert_nil TimeUtil.parse_date(nil)
  end

  test 'parse_date with an unrecognizable argument returns nil' do
    assert_nil TimeUtil.parse_date('cats')
  end

  test 'parse_date works with YYYY:MM:DD HH:MM:SS' do
    assert_equal [Time.parse('1923-02-12 12:10:50')],
                 TimeUtil.parse_date('1923:02:12 12:10:50')
  end

  test 'parse_date works with YYYY-MM-DD' do
    assert_equal [Time.parse('1923-02-12 00:00:00')],
                 TimeUtil.parse_date('1923-02-12')
  end

  test 'parse_date works with YYYY:MM:DD' do
    assert_equal [Time.parse('1923-02-12 00:00:00')],
                 TimeUtil.parse_date('1923:02:12')
  end

  test 'parse_date works with YYYY' do
    assert_equal [Time.parse('1923-01-01 00:00:00')],
                 TimeUtil.parse_date('1923')
  end

  test 'parse_date works with [YYYY]' do
    assert_equal [Time.parse('1923-01-01 00:00:00')],
                 TimeUtil.parse_date('[1923]')
  end

  test 'parse_date works with [YYYY?]' do
    assert_equal [Time.parse('1923-01-01 00:00:00')],
                 TimeUtil.parse_date('[1923?]')
  end

  test 'parse_date works with ISO 8601' do
    assert_equal [Time.parse('1923-02-12 00:00:00')],
                 TimeUtil.parse_date('1923-02-12 00:00:00')
  end

end
