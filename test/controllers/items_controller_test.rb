require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @item = items(:free_form_dir1_dir1_file1)
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

