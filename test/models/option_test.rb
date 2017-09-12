require 'test_helper'

class OptionTest < ActiveSupport::TestCase

  # boolean()

  test 'boolean() works' do
    key = 'bla'
    Option.create!(key: key, value: true)
    assert Option.boolean(key)
  end

  test 'boolean() returns nil for nonexistent keys' do
    assert_nil Option.boolean('bogus')
  end

  # integer()

  test 'integer() returns an integer for existing keys' do
    key = 'bla'
    Option.create!(key: key, value: 123)
    assert_equal 123, Option.integer(key)
  end

  test 'integer() returns nil for nonexistent keys' do
    assert_nil Option.integer('bogus')
  end

  # set()

  test 'set() updates the value of an existing key' do
    key = 'cats'
    Option.set(key, 'test')
    assert_equal 'test', Option.string(key)
    Option.set(key, 'test2')
    assert_equal 'test2', Option.string(key)
  end

  test 'set() creates a new Option for a new key' do
    key = 'cats'
    assert_nil Option.find_by_key(key)
    Option.set(key, 'test')
    assert_not_nil Option.find_by_key(key)
  end

  # string()

  test 'string() works' do
    key = 'bla'
    Option.create!(key: key, value: 'cats')
    assert_equal 'cats', Option.string(key)
  end

  test 'string() returns nil for nonexistent keys' do
    assert_nil Option.string('bogus')
  end

end
