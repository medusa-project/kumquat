require 'test_helper'

module Admin

  class ItemsControllerTest < ActionController::TestCase

    setup do
      session[:user] = users(:one).id
    end

    test 'index with html format should work' do
      get :index
      assert_response :success
    end

    test 'index with tsv format should work' do
      get :index, format: :tsv
      assert_response :success
    end

  end

end
