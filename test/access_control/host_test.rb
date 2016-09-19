require 'test_helper'

class HostTest < ActiveSupport::TestCase

  test 'pattern can contain only certain characters' do
    Host.create!(pattern: 'ABCabc123.*_-:')

    assert_raises ActiveRecord::RecordInvalid do
      Host.create!(pattern: 'abc abc')
    end
    assert_raises ActiveRecord::RecordInvalid do
      Host.create!(pattern: '123. 242.*')
    end
  end

  test 'patterh_matches?() should work' do
    host = Host.new(pattern: '123.123.*')
    assert host.pattern_matches?('123.123.123.123')
    assert host.pattern_matches?('123.123.234.234')
    assert !host.pattern_matches?('214.123.123.123')

    host = Host.new(pattern: '*.example.org')
    assert host.pattern_matches?('example.org')
    assert host.pattern_matches?('cats.example.org')
    assert !host.pattern_matches?('dogs.example.com')
  end

end
