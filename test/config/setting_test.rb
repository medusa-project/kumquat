require 'test_helper'

class SettingTest < ActiveSupport::TestCase

  # boolean()

  test 'boolean() works' do
    key = 'bla'
    Setting.create!(key: key, value: true)
    assert Setting.boolean(key)
  end

  test 'boolean() returns nil for nonexistent keys' do
    assert_nil Setting.boolean('bogus')
  end

  test 'boolean() returns the provided default value for nonexistent keys' do
    assert Setting.boolean('bogus', true)
  end

  # integer()

  test 'integer() returns an integer for existing keys' do
    key = 'bla'
    Setting.create!(key: key, value: 123)
    assert_equal 123, Setting.integer(key)
  end

  test 'integer() returns nil for nonexistent keys' do
    assert_nil Setting.integer('bogus')
  end

  test 'integer() returns the provided default value for nonexistent keys' do
    assert_equal 30, Setting.integer('bogus', 30)
  end

  # set()

  test 'set() updates the value of an existing key' do
    key = 'cats'
    Setting.set(key, 'test')
    assert_equal 'test', Setting.string(key)
    Setting.set(key, 'test2')
    assert_equal 'test2', Setting.string(key)
  end

  test 'set() creates a new Setting for a new key' do
    key = 'cats'
    assert_nil Setting.find_by_key(key)
    Setting.set(key, 'test')
    assert_not_nil Setting.find_by_key(key)
  end

  # string()

  test 'string() works' do
    key = 'bla'
    Setting.create!(key: key, value: 'cats')
    assert_equal 'cats', Setting.string(key)
  end

  test 'string() returns nil for nonexistent keys' do
    assert_nil Setting.string('bogus')
  end

  test 'string() returns the provided default value for nonexistent keys' do
    assert_equal "cats", Setting.string('bogus', "cats")
  end

end
