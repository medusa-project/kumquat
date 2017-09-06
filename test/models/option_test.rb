require 'test_helper'

class OptionTest < ActiveSupport::TestCase

  test 'boolean() works' do
    key = 'bla'
    Option.create!(key: key, value: '{ "value": true }')
    assert Option.boolean(key)
  end

end
