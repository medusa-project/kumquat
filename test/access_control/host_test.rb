require 'test_helper'

class HostTest < ActiveSupport::TestCase

  test 'pattern can contain only certain characters' do
    Host.create!(pattern: 'ABCabc123.*_-')

    assert_raises ActiveRecord::RecordInvalid do
      Host.create!(pattern: 'abc abc')
    end
    assert_raises ActiveRecord::RecordInvalid do
      Host.create!(pattern: '123. 242.*')
    end
  end

  # ip?()

  test 'ip?() should work' do
    host = Host.new(pattern: '123.123.*')
    assert host.ip?('123.123.*')
    host = Host.new(pattern: '123.123.10.1')
    assert host.ip?('123.123.10.1')
    host = Host.new(pattern: 'example.org')
    assert !host.ip?('example.org')
    host = Host.new(pattern: '*.example.org')
    assert !host.ip?('*.example.org')
  end

  # ip_range?()

  test 'ip_range?() should work' do
    host = Host.new(pattern: '123.123.*')
    assert !host.ip_range?('123.123.*')
    host = Host.new(pattern: '123.123.10.1')
    assert !host.ip_range?('123.123.10.1')
    host = Host.new(pattern: 'example.org')
    assert !host.ip_range?('example.org')

    host = Host.new(pattern: 'example-example.org')
    assert !host.ip_range?('example-example.org')

    host = Host.new(pattern: '123.123.*-123.124.*')
    assert host.ip_range?('123.123.*-123.124.*')
  end

  # pattern_matches?()

  test 'pattern_matches?() should work with IP addresses' do
    host = Host.new(pattern: '123.123.*')
    assert host.pattern_matches?('123.123.123.123')
    assert host.pattern_matches?('123.123.234.234')
    assert !host.pattern_matches?('214.123.123.123')
  end

  test 'pattern_matches?() should work with IP address ranges' do
    host = Host.new(pattern: '123.123.*-123.130.*')
    assert host.pattern_matches?('123.123.123.123')
    assert host.pattern_matches?('123.123.127.*')
    assert !host.pattern_matches?('123.120.123.*')
    assert !host.pattern_matches?('123.131.123.*')
  end

  test 'pattern_matches?() should work with hostnames' do
    host = Host.new(pattern: '*.example.org')
    assert host.pattern_matches?('example.org')
    assert host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  # within_range?()

  test 'within_range?() should work' do
    host = Host.new(pattern: '123.123.*-123.130.*')
    assert host.within_range?('123.126.12.10', '123.123.*', '123.130.*')
    assert !host.within_range?('123.122.16.2', '123.123.*', '123.130.*')
    assert !host.within_range?('123.131.16.2', '123.123.*', '123.130.*')
  end

end
