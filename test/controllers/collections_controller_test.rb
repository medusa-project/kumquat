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

  test 'iiif_presentation() only returns top-level items' do 
    Item.reindex_all
    refresh_opensearch

    get collection_iiif_presentation_path(@collection)
    assert_response :success 

    json = JSON.parse(response.body)

    actual_ids = json.fetch('members').map do |member|
      member.fetch('@id')
    end

    expected_ids = [item_iiif_manifest_url(items(:compound_object_1001)),
                    item_iiif_manifest_url(items(:compound_object_1002))]
    
    excluded_items = [items(:compound_object_1002_page1), 
                      items(:compound_object_1002_page2), 
                      items(:compound_object_1002_supplement)]

    excluded_items.each do |item|
      refute_includes actual_ids, item_iiif_manifest_url(item)
    end

    assert_equal expected_ids, actual_ids
  end

  test 'iiif_presentation() excludes unpublished and restricted items' do 
    unpublished = items(:compound_object_1001).dup
    unpublished.assign_attributes(repository_id: SecureRandom.uuid, 
                                  published: false)
    
    unpublished.elements.build(name: 'title', value: 'Unpublished')
    unpublished.save!

    restricted = items(:compound_object_1001).dup
    restricted.assign_attributes(repository_id: SecureRandom.uuid, 
                                  allowed_netids: [{ netid: 'bogus',
                                                    expires: Time.now.to_i + 1.year }])
    restricted.elements.build(name: 'title', value: 'Restricted')
    restricted.save!

    Item.reindex_all
    refresh_opensearch

    get collection_iiif_presentation_path(@collection)
    assert_response :success

    json = JSON.parse(response.body)
    actual_ids = json.fetch('members').map { |member| member.fetch('@id') }

    refute_includes actual_ids, item_iiif_manifest_url(unpublished)
    refute_includes actual_ids, item_iiif_manifest_url(restricted)
    assert_includes actual_ids, item_iiif_manifest_url(items(:compound_object_1001))
  end

    
  test 'iiif_presentation() uses structural sort for free-form collections' do
    free_form = collections(:free_form)
    repository_ids = ['00000000-0000-4000-8000-000000000002',
                      '00000000-0000-4000-8000-000000000001']

    repository_ids.each do |repository_id|
      item = items(:compound_object_1001).dup
      item.assign_attributes(repository_id: repository_id,
                             collection_repository_id: free_form.repository_id)
      item.elements.build(name: 'title', value: "Item #{repository_id}")
      item.save!
    end

    Item.reindex_all
    refresh_opensearch

    get collection_iiif_presentation_path(free_form)
    assert_response :success

    actual_ids = JSON.parse(response.body).fetch('members').map { |m| m.fetch('@id') }

    # Free-form fixture collection also has a top-level directory; only the
    # relative order of the two added items is asserted.
    expected_ids = repository_ids.sort.map do |repository_id|
      item_iiif_manifest_url(Item.find_by!(repository_id: repository_id))
    end
    assert_equal expected_ids, actual_ids.select { |id| expected_ids.include?(id) }
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

