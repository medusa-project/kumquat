require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @user = User.create!(username: 'bogus')
    assert_not_empty @user.api_key
  end

  # email()

  test 'email returns a correct address' do
    assert_equal 'bogus@illinois.edu', @user.email
  end

  # reset_api_key()

  test 'reset_api_key() works' do
    key = @user.api_key
    @user.reset_api_key
    assert_not_equal key, @user.api_key
  end

  # watching?()

  test 'watching?() returns true for a watching collection' do
    collection = collections(:compound_object)
    @user.watches.build(collection: collection)
    @user.save!
    assert @user.watching?(collection)
  end

  test 'watching?() returns false for a non-watching collection' do
    collection = collections(:compound_object)
    assert !@user.watching?(collection)
  end

end
