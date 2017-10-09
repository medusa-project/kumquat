require 'test_helper'

class OptionTest < ActiveSupport::TestCase

  # boolean()

  test 'boolean() works' do
    key = 'bla'
    Option.create!(key: key, value: '{ "value": true }')
    assert Option.boolean(key)
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

end
