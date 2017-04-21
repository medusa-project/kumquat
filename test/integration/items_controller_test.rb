require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @item = items(:illini_union_dir1_file1)
  end

  # show() access control

  test 'show() should restrict access to role-restricted items' do
    role = Role.new(key: 'test', name: 'Test')
    role.hosts.build(pattern: 'www.example.com')
    role.save!
    @item.denied_roles << role
    @item.save!

    get('/items/' + @item.repository_id)
    assert_response :forbidden
  end

  # show() with JSON

  test 'show() JSON should return 200' do
    get('/items/' + @item.repository_id + '.json')
    assert_response :success
  end

end

