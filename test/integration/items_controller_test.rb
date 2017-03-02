require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @valid_xml = File.read(__dir__ + '/../fixtures/repository/item.xml')
  end

  # show() access control

  test 'show() should restrict access to role-restricted items' do
    role = Role.new(key: 'test', name: 'Test')
    role.hosts.build(pattern: 'localhost')
    role.save!
    item = items(:item1)
    item.denied_roles << role
    item.save!

    get('/items/' + item.repository_id)
    assert_response :forbidden
  end

  # show() with JSON

  test 'show() JSON should return 200' do
    get('/items/' + items(:item1).repository_id + '.json')
    assert_response :success
  end

end

