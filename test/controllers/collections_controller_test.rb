require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_opensearch
    @collection = collections(:compound_object)
    sign_out
  end

  # iiif_presentation()

  test 'iiif_presentation() returns HTTP 200' do
    get collection_iiif_presentation_path(@collection)
    assert_response :success
  end

  test 'iiif_presentation() returns HTTP 403 for host group-restricted collections' do
    @collection.allowed_host_groups << host_groups(:yellow)
    @collection.save!

    get collection_iiif_presentation_path(@collection)
    assert_response :forbidden
  end

  test 'iiif_presentation() returns HTTP 403 for restricted collections for not-logged-in users' do
    @collection.update!(restricted: true)

    get collection_iiif_presentation_path(@collection)
    assert_response :forbidden
  end

  test 'iiif_presentation() returns HTTP 403 for restricted collections for logged-in users' do
    sign_in_as(users(:medusa_user))
    @collection.update!(restricted: true)

    get collection_iiif_presentation_path(@collection)
    assert_response :forbidden
  end

  test 'iiif_presentation() returns HTTP 200 for restricted collections for administrators' do
    sign_in_as(users(:medusa_admin))
    @collection.update!(restricted: true)

    get collection_iiif_presentation_path(@collection)
    assert_response :ok
  end

  # iiif_presentation_list()

  test 'iiif_presentation_list() returns HTTP 200' do
    get collections_iiif_presentation_list_path
    assert_response :success
  end

  # index()

  test 'index() redirects to the Search Gateway' do
    get collections_path
    assert_response :moved_permanently
    assert_redirected_to ::Configuration.instance.metadata_gateway_url + '/collections'
  end

  # show()

  test 'show() returns HTTP 200 for HTML' do
    get collection_path(@collection)
    assert_response :success
  end

  test 'show() returns HTTP 200 for JSON' do
    get collection_path(@collection, format: :json)
    assert_response :success
  end

  test 'show() returns HTTP 403 for host group-restricted collections' do
    @collection.allowed_host_groups << host_groups(:yellow)
    @collection.save!

    get collection_path(@collection)
    assert_response :forbidden
  end

  test 'show() returns HTTP 403 for restricted collections for not-logged-in users' do
    @collection.update!(restricted: true)
    get collection_path(@collection)
    assert_response :forbidden
  end

  test 'show() returns HTTP 403 for restricted collections for logged-in users' do
    sign_in_as(users(:medusa_user))
    @collection.update!(restricted: true)
    get collection_path(@collection)
    assert_response :forbidden
  end

  test 'show() returns HTTP 200 for restricted collections for administrators' do
    sign_in_as(users(:medusa_admin))
    @collection.update!(restricted: true)
    get collection_path(@collection)
    assert_response :ok
  end

  # show_contentdm()

  test 'show_contentdm() redirects' do
    @collection = collections(:contentdm)
    get '/projects/' + @collection.contentdm_alias
    assert_redirected_to '/collections/' + @collection.repository_id

    get '/projects/' + @collection.contentdm_alias.upcase
    assert_redirected_to '/collections/' + @collection.repository_id

    get '/projects/' + @collection.contentdm_alias + '/cats.html'
    assert_redirected_to '/collections/' + @collection.repository_id
  end

end

