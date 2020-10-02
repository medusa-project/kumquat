require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @collection = collections(:compound_object)
  end

  # show() access control

  test 'show() restricts access to host group-restricted collections' do
    # N.B.: Rails sets request.host to this pattern
    group = HostGroup.create!(key: 'test',
                              name: 'Test',
                              pattern: 'www.example.com')
    @collection.denied_host_groups << group
    @collection.save!

    get('/collections/' + @collection.repository_id)
    assert_response :forbidden
  end

  # show()

  test 'show() returns HTTP 200 for HTML' do
    get('/collections/' + @collection.repository_id)
    assert_response :success
  end

  test 'show() returns HTTP 200 for JSON' do
    get('/collections/' + @collection.repository_id + '.json')
    assert_response :success
  end

  test 'show() returns HTTP 403 for restricted collections for not-logged-in users' do
    @collection.update!(restricted: true)
    get('/collections/' + @collection.repository_id)
    assert_response :forbidden
  end

  test 'show() returns HTTP 403 for restricted collections for logged-in users' do
    sign_in_as(users(:normal))
    @collection.update!(restricted: true)
    get('/collections/' + @collection.repository_id)
    assert_response :forbidden
  end

  test 'show() returns HTTP 200 for restricted collections for administrators' do
    sign_in_as(users(:admin))
    @collection.update!(restricted: true)
    get('/collections/' + @collection.repository_id)
    assert_response :ok
  end

  # show_contentdm

  test 'show_contentdm() should redirect' do
    @collection = collections(:contentdm)
    get '/projects/' + @collection.contentdm_alias
    assert_redirected_to '/collections/' + @collection.repository_id

    get '/projects/' + @collection.contentdm_alias.upcase
    assert_redirected_to '/collections/' + @collection.repository_id

    get '/projects/' + @collection.contentdm_alias + '/cats.html'
    assert_redirected_to '/collections/' + @collection.repository_id
  end

end

