require 'test_helper'

class ContentProfileTest < ActiveSupport::TestCase

  test 'all() should return the correct profiles' do
    all = ContentProfile.all
    assert_equal 2, all.length

    # free-form profile
    assert_equal 0, all[0].id
    assert_equal 'Free-Form', all[0].name

    # map profile
    assert_equal 1, all[1].id
    assert_equal 'Map', all[1].name
  end

  test 'find() should return the correct profile' do
    assert_not_nil ContentProfile.find(1)
    assert_nil ContentProfile.find(27)
  end

end
