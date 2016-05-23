require 'test_helper'

module Admin

  class ItemsControllerTest < ActionController::TestCase

    setup do
      session[:user] = users(:one).id
    end

    test 'index with html format should work' do
      get :index, collection_id: collections(:collection1).repository_id
      assert_response :success
    end

    test 'index with tsv format should work' do
      get :index, collection_id: collections(:collection1).repository_id,
          format: :tsv
      assert_response :success
    end

    test 'index with tsv format and no items should return a heading' do
      Item.destroy_all
      get :index, collection_id: collections(:collection1).repository_id,
          format: :tsv
      assert response.body.split("\n\r").length == 1
    end

  end

end
