require 'test_helper'

class HostGroupTest < ActiveSupport::TestCase

  # all_matching_hostname_or_ip()

  test 'all_matching_hostname_or_ip() returns an empty set when there are no matches' do
    HostGroup.create!(key: 'test', name: 'Test',
                      pattern: "*.cats.org\n202.202.*")
    HostGroup.create!(key: 'test2', name: 'Test2',
                      pattern: "*.dogs.org\n12.12.*")
    assert_empty HostGroup.all_matching_hostname_or_ip('example.org', '123.123.123.123')
  end

  test 'all_matching_host_or_ip() returns host groups with matching hostnames' do
    HostGroup.create!(key: 'test', name: 'Test',
                      pattern: "*cats.org\n202.202.*")
    HostGroup.create!(key: 'test2', name: 'Test2',
                      pattern: "*dogs.org\n12.12.*")
    assert_equal 1, HostGroup.all_matching_hostname_or_ip('cats.org', '123.123.123.123').length
  end

  test 'all_matching_host_or_ip() returns host groups with matching IP addresses' do
    HostGroup.create!(name: 'Test', key: 'test',
                      pattern: "*.cats.org\n202.202.*")
    HostGroup.create!(name: 'Test2', key: 'test2',
                      pattern: "*.dogs.org\n12.12.*")
    assert_equal 1, HostGroup.all_matching_hostname_or_ip('example.org', '12.12.12.12').length
  end

  # comment()

  test 'comment() returns the comment' do
    host = HostGroup.new(pattern: '123.123.* # some range')
    assert_equal 'some range', host.comment
    host = HostGroup.new(pattern: '# 123.123.*')
    assert_equal '123.123.*', host.comment
    host = HostGroup.new(pattern: '* # some range')
    assert_equal 'some range', host.comment
  end

  test 'comment() returns nil when there is no comment' do
    host = HostGroup.new(pattern: '123.123.*')
    assert_nil host.comment
    host = HostGroup.new(pattern: '*')
    assert_nil host.comment
  end

  # pattern_matches?()

  test 'pattern_matches?() returns false when pattern is commented out' do
    host = HostGroup.new(pattern: '# 123.123.*')
    assert !host.pattern_matches?('123.123.123.123')
  end

  test 'pattern_matches?() works with IPs' do
    host = HostGroup.new(pattern: '123.123.*')
    assert host.pattern_matches?('123.123.123.123')
    assert host.pattern_matches?('123.123.234.234')
    assert !host.pattern_matches?('214.123.123.123')
  end

  test 'pattern_matches?() works with IP wildcard ranges' do
    host = HostGroup.new(pattern: '123.123.*-123.130.*')
    assert host.pattern_matches?('123.123.123.123')
    assert host.pattern_matches?('123.123.127.*')
    assert !host.pattern_matches?('123.120.123.*')
    assert !host.pattern_matches?('123.131.123.*')
  end

  test 'pattern_matches?() works with IP CIDR ranges' do
    host = HostGroup.new(pattern: '123.123.0.0/16')
    assert host.pattern_matches?('123.123.123.123')
    assert !host.pattern_matches?('123.125.123.123')
  end

  test 'pattern_matches?() works with hostnames' do
    host = HostGroup.new(pattern: 'example.org')
    assert host.pattern_matches?('example.org')
    assert !host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  test 'pattern_matches?() works with wildcards at the beginning of hostnames' do
    host = HostGroup.new(pattern: '*.example.org')
    assert host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  test 'pattern_matches?() works with wildcards at the end of hostnames' do
    host = HostGroup.new(pattern: 'example.*')
    assert host.pattern_matches?('example.org')
    assert !host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  test 'pattern_matches?() works with wildcards in the middle of hostnames' do
    host = HostGroup.new(pattern: 'test.*.org')
    assert host.pattern_matches?('test.example.org')
    assert !host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  test 'pattern_matches?() works with wildcards at the beginning, middle, and end of hostnames' do
    host = HostGroup.new(pattern: '*.*.example.*')
    assert host.pattern_matches?('test.test.example.org')
    assert !host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

  # validate()

  test 'validate() checks for the presence of a pattern' do
    host = HostGroup.new(key: 'test', name: 'Test',
                         pattern: '')
    assert !host.valid?
  end

  test 'validate() rejects invalid general patterns' do
    host = HostGroup.new(key: 'test', name: 'Test',
                         pattern: '# only a comment')
    assert !host.valid?

    host.pattern = '*'
    assert !host.valid?

    host.pattern = '* # some comment'
    assert !host.valid?
  end

  test 'validate() rejects invalid host patterns' do
    host = HostGroup.new(key: 'test', name: 'Test',
                         pattern: 'host.example.*')
    assert !host.valid?

    host.pattern = '?.example.org'
    assert !host.valid?

    host.pattern = 'ex_ample.org'
    assert !host.valid?
  end

  test 'validate() rejects invalid IP patterns' do
    host = HostGroup.new(key: 'test', name: 'Test',
                         pattern: '1234.2342.2342.2342')
    assert !host.valid?
  end

  test 'validate() allows valid host patterns' do
    host = HostGroup.new(key: 'test', name: 'Test',
                         pattern: 'CATS-dogs-123.example.org # comment')
    assert host.valid?

    host.pattern = '*.example.org # comment'
    assert host.valid?
  end

  test 'validate() allows valid IP patterns' do
    host = HostGroup.new(key: 'test', name: 'Test',
                         pattern: '123.123.123.123 # comment')
    assert host.valid?

    host.pattern = '123.123.* # comment'
    assert host.valid?

    host.pattern = '123.123.0.0/16 # comment'
    assert host.valid?
  end

end
