require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @collection = collections(:sanborn)
  end

  # show() access control

  test 'show() restricts access to host group-restricted collections' do
    # N.B.: Rails sets request.host to this pattern
    group = HostGroup.create!(key: 'test', name: 'Test',
                              pattern: 'www.example.com')
    @collection.denied_host_groups << group
    @collection.save!

    get('/collections/' + @collection.repository_id)
    assert_response :forbidden
  end

  # show()

  test 'show() should return 200' do
    get('/collections/' + @collection.repository_id)
    assert_response :success
  end

  # show() with JSON

  test 'show() JSON should return 200' do
    get('/collections/' + @collection.repository_id + '.json')
    assert_response :success
  end

  # show_contentdm

  test 'show_contentdm() should redirect' do
    get '/projects/' + @collection.contentdm_alias
    assert_redirected_to '/collections/' + @collection.repository_id

    get '/projects/' + @collection.contentdm_alias.upcase
    assert_redirected_to '/collections/' + @collection.repository_id

    get '/projects/' + @collection.contentdm_alias + '/cats.html'
    assert_redirected_to '/collections/' + @collection.repository_id
  end

end

