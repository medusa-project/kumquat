require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @collection = collections(:sanborn)
  end

  # show() access control

  test 'show() should restrict access to role-restricted collections' do
    role = Role.new(key: 'test', name: 'Test')
    role.hosts.build(pattern: 'www.example.com') # Rails sets request.host to this
    role.save!
    @collection.denied_roles << role
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

end

