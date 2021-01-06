require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @item = items(:free_form_dir1_dir1_file1)
  end

  # binary()

  test 'binary() returns HTTP 200 for a valid filename' do
    @item = items(:compound_object_1001)
    get item_binary_path(@item, @item.binaries.first.filename)
    assert_response :ok
  end

  test 'binary() returns HTTP 404 for an invalid filename' do
    get item_binary_path(@item, 'bogus.jpg')
    assert_response :not_found
  end

  # iiif_annotation_list()

  test 'iiif_annotation_list() returns HTTP 200 for a valid item' do
    get item_iiif_annotation_list_path(@item, @item.repository_id)
    assert_response :ok
  end

  test 'iiif_annotation_list() returns HTTP 404 for an invalid item' do
    get item_iiif_annotation_list_path('bogus', 'bogus-name')
    assert_response :not_found
  end

  # iiif_canvas()

  test 'iiif_canvas() returns HTTP 200 for a valid item' do
    get item_iiif_canvas_path(@item, 'any-name')
    assert_response :ok
  end

  test 'iiif_canvas() returns HTTP 404 for an invalid item' do
    get item_iiif_canvas_path('bogus', 'any-name')
    assert_response :not_found
  end

  # iiif_image_resource()

  test 'iiif_image_resource() returns HTTP 200 for a valid item and a valid
  resource name' do
    get item_iiif_image_resource_path(@item, 'access')
    assert_response :ok
    get item_iiif_image_resource_path(@item, 'preservation')
    assert_response :ok
  end

  test 'iiif_image_resource() returns HTTP 404 for a valid item and an invalid
  resource name' do
    get item_iiif_image_resource_path(@item, 'bogus')
    assert_response :not_found
  end

  test 'iiif_image_resource() returns HTTP 404 for an invalid item' do
    get item_iiif_image_resource_path('bogus', 'access')
    assert_response :not_found
  end

  # iiif_layer()

  test 'iiif_layer() returns HTTP 200 for a valid item' do
    get item_iiif_layer_path(@item, @item)
    assert_response :ok
  end

  test 'iiif_layer() returns HTTP 404 for an invalid item' do
    get item_iiif_layer_path('bogus', 'bogus')
    assert_response :not_found
  end

  # iiif_manifest()

  test 'iiif_manifest() returns HTTP 200 for a valid item' do
    get item_iiif_manifest_path(@item, 'name-doesnt-matter')
    assert_response :ok
  end

  test 'iiif_manifest() returns HTTP 404 for an invalid item' do
    get item_iiif_manifest_path('bogus', 'name-doesnt-matter')
    assert_response :not_found
  end

  # iiif_media_sequence()

  test 'iiif_media_sequence() returns HTTP 200 for a valid item' do
    get item_iiif_media_sequence_path(@item, 'name-doesnt-matter')
    assert_response :ok
  end

  test 'iiif_media_sequence() returns HTTP 404 for an invalid item' do
    get item_iiif_media_sequence_path('bogus', 'name-doesnt-matter')
    assert_response :not_found
  end

  # iiif_range()

  test 'iiif_range() returns HTTP 200 for a valid item and subitem' do
    @item    = items(:compound_object_1002)
    @subitem = items(:compound_object_1002_page1)
    get item_iiif_range_path(@item, @subitem)
    assert_response :ok
  end

  test 'iiif_range() returns HTTP 404 for an invalid subitem' do
    @subitem = items(:compound_object_1002)
    @item    = items(:compound_object_1002_page1)
    get item_iiif_range_path(@item, @subitem)
    assert_response :not_found
  end

  # iiif_sequence()

  test 'iiif_sequence() returns HTTP 200 for a valid parent item and sequence name' do
    @item = items(:compound_object_1002)
    get item_iiif_sequence_path(@item, 'item')
    assert_response :ok
    get item_iiif_sequence_path(@item, 'page')
    assert_response :ok
  end

  test 'iiif_sequence() returns HTTP 404 for a valid parent item and invalid sequence name' do
    @item = items(:compound_object_1002)
    get item_iiif_sequence_path(@item, 'bogus')
    assert_response :not_found
  end

  test 'iiif_sequence() returns HTTP 404 for a child item and valid sequence name' do
    @item = items(:compound_object_1002_page1)
    get item_iiif_sequence_path(@item, 'item')
    assert_response :not_found
  end

  test 'iiif_sequence() returns HTTP 404 for an invalid item' do
    get item_iiif_sequence_path('bogus', 'item')
    assert_response :not_found
  end

  # index()

  test 'index()' do
    # TODO: write tests for this
  end

  # show() access control

  test 'show() allows access to non-expired restricted items by the correct NetID' do
    sign_in_as(users(:normal))
    @item.allowed_netids = [{ netid: 'normal',
                              expires: Time.now.to_i + 1.day.to_i }]
    @item.save!

    get('/items/' + @item.repository_id)
    assert_response :ok
  end

  test 'show() allows access to non-expired restricted items by logged-in administrators' do
    sign_in_as(users(:admin))
    @item.allowed_netids = [{ netid: 'normal',
                              expires: Time.now.to_i + 1.day.to_i }]
    @item.save!

    get('/items/' + @item.repository_id)
    assert_response :ok
  end

  test 'show() allows access to expired restricted items by logged-in administrators' do
    sign_in_as(users(:admin))
    @item.allowed_netids = [{ netid: 'normal',
                              expires: Time.now.to_i - 1.day.to_i }]
    @item.save!

    get('/items/' + @item.repository_id)
    assert_response :ok
  end

  test 'show() forbids access to expired restricted items by the correct NetID' do
    sign_in_as(users(:normal))
    @item.allowed_netids = [{ netid: 'normal',
                              expires: Time.now.to_i - 1.day.to_i }]
    @item.save!

    get('/items/' + @item.repository_id)
    assert_response :forbidden
  end

  test 'show() forbids access to restricted items with an incorrect NetID' do
    sign_in_as(users(:normal))
    @item.allowed_netids = [{ netid: 'user',
                              expires: Time.now.to_i + 1.day.to_i }]
    @item.save!

    get('/items/' + @item.repository_id)
    assert_response :forbidden
  end

  test 'show() redirects to the sign-in route for restricted items for not-logged-in users' do
    @item.allowed_netids = [{ netid: 'user',
                              expires: Time.now.to_i + 1.day.to_i }]
    @item.save!

    get('/items/' + @item.repository_id)
    assert_redirected_to signin_path
  end

  test 'show() restricts access to host group-restricted items' do
    # N.B.: Rails sets request.host to this pattern
    group = HostGroup.create!(key: 'test', name: 'Test',
                              pattern: 'www.example.com')
    @item.denied_host_groups << group
    @item.save!

    get('/items/' + @item.repository_id)
    assert_response :forbidden
  end

  # show() with JSON

  test 'show() JSON returns HTTP 200' do
    get('/items/' + @item.repository_id + '.json')
    assert_response :success
  end

end

