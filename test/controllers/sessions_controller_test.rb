require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

  # create()

  test 'signing in redirects to the admin page by default' do
    sign_in_as(users(:admin))
    assert_redirected_to admin_root_path
  end

  test 'signing in redirects to the requested URL if provided' do
=begin TODO: get this to work
    session[:return_to] = 'http://example.org/cats'
    sign_in_as(users(:admin))
    assert_redirected_to session[:return_to]
=end
  end

  test 'signing in as a Medusa user' do
    sign_in_as(users(:admin))
    assert_redirected_to admin_root_path
  end

  test 'signing in as a non-Medusa user' do
    sign_in_as("johnsmith")
    assert_redirected_to root_path
  end

  # destroy()

  test 'signing out redirects to the root path' do
    sign_in_as(users(:admin))
    sign_out
    assert_redirected_to root_url
  end

  test 'signing out clears the session cookie' do
    sign_in_as(users(:admin))
    sign_out
    assert_nil session[:user]
  end

  # new()

  test 'new() redirects to the sign-in path' do
    get '/signin'
    assert_redirected_to '/auth/developer'
  end

end
