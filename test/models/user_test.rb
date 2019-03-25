require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @user = User.create!(username: 'bogus')
    assert_not_empty @user.api_key
  end

  test 'reset_api_key works' do
    key = @user.api_key
    @user.reset_api_key
    assert_not_equal key, @user.api_key
  end

end
