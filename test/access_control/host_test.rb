require 'test_helper'

class HostTest < ActiveSupport::TestCase

  # comment()

  test 'comment() returns the comment' do
    host = Host.new(pattern: '123.123.* # some range')
    assert_equal 'some range', host.comment
    host = Host.new(pattern: '# 123.123.*')
    assert_equal '123.123.*', host.comment
    host = Host.new(pattern: '* # some range')
    assert_equal 'some range', host.comment
  end

  test 'comment() returns nil when there is no comment' do
    host = Host.new(pattern: '123.123.*')
    assert_nil host.comment
    host = Host.new(pattern: '*')
    assert_nil host.comment
  end

  # commented_out?()

  test 'commented_out?() returns true when the pattern is commented out' do
    host = Host.new(pattern: '# 123.123.*')
    assert host.commented_out?
  end

  test 'commented_out?() returns false when the pattern is not commented out' do
    host = Host.new(pattern: '123.123.* # some range')
    assert !host.commented_out?
    host = Host.new(pattern: '123.123.*')
    assert !host.commented_out?
  end

  # pattern_matches?()

  test 'pattern_matches?() should return false when pattern is commented out' do
    host = Host.new(pattern: '# 123.123.*')
    assert !host.pattern_matches?('123.123.123.123')
  end

  test 'pattern_matches?() should work with IPs' do
    host = Host.new(pattern: '123.123.*')
    assert host.pattern_matches?('123.123.123.123')
    assert host.pattern_matches?('123.123.234.234')
    assert !host.pattern_matches?('214.123.123.123')
  end

  test 'pattern_matches?() should work with IP wildcard ranges' do
    host = Host.new(pattern: '123.123.*-123.130.*')
    assert host.pattern_matches?('123.123.123.123')
    assert host.pattern_matches?('123.123.127.*')
    assert !host.pattern_matches?('123.120.123.*')
    assert !host.pattern_matches?('123.131.123.*')
  end

  test 'pattern_matches?() should work with IP CIDR ranges' do
    host = Host.new(pattern: '123.123.0.0/16')
    assert host.pattern_matches?('123.123.123.123')
    assert !host.pattern_matches?('123.125.123.123')
  end

  test 'pattern_matches?() should work with hostnames' do
    host = Host.new(pattern: 'example.org')
    assert host.pattern_matches?('example.org')
    assert !host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  test 'pattern_matches?() should work with wildcards at the beginning of hostnames' do
    host = Host.new(pattern: '*.example.org')
    assert host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  test 'pattern_matches?() should work with wildcards at the end of hostnames' do
    host = Host.new(pattern: 'example.*')
    assert host.pattern_matches?('example.org')
    assert !host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  test 'pattern_matches?() should work with wildcards in the middle of hostnames' do
    host = Host.new(pattern: 'test.*.org')
    assert host.pattern_matches?('test.example.org')
    assert !host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  test 'pattern_matches?() should work with wildcards at the beginning, middle, and end of hostnames' do
    host = Host.new(pattern: '*.*.example.*')
    assert host.pattern_matches?('test.test.example.org')
    assert !host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  # uncommented_pattern()

  test 'uncommented_pattern() returns the pattern without comments' do
    host = Host.new(pattern: '*.example.org # this is a host')
    assert_equal '*.example.org', host.uncommented_pattern

    host.pattern = '*.example.org'
    assert_equal '*.example.org', host.uncommented_pattern
  end

  # validate()

  test 'validate() should check for the presence of a pattern' do
    host = Host.new(pattern: '')
    assert !host.valid?
  end

  test 'validate() should reject invalid general patterns' do
    host = Host.new(pattern: '# only a comment')
    assert !host.valid?

    host.pattern = '*'
    assert !host.valid?

    host.pattern = '* # some comment'
    assert !host.valid?
  end

  test 'validate() should reject invalid host patterns' do
    host = Host.new(pattern: 'host.example.*')
    assert !host.valid?

    host.pattern = '?.example.org'
    assert !host.valid?

    host.pattern = 'ex_ample.org'
    assert !host.valid?
  end

  test 'validate() should reject invalid IP patterns' do
    host = Host.new(pattern: '1234.2342.2342.2342')
    assert !host.valid?
  end

  test 'validate() should allow valid host patterns' do
    host = Host.new(pattern: 'CATS-dogs-123.example.org # comment')
    assert host.valid?

    host.pattern = '*.example.org # comment'
    assert host.valid?
  end

  test 'validate() should allow valid IP patterns' do
    host = Host.new(pattern: '123.123.123.123 # comment')
    assert host.valid?

    host.pattern = '123.123.* # comment'
    assert host.valid?

    host.pattern = '123.123.0.0/16 # comment'
    assert host.valid?
  end

end
