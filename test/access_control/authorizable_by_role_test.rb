require 'test_helper'

class AuthorizableByRoleTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:sanborn)
  end

  # authorized_by_any_roles?()

  test 'authorized_by_any_roles?() should return false if given no roles but
  the instance has allowed roles' do
    @collection.allowed_roles << roles(:users)
    assert !@collection.authorized_by_any_roles?([])
  end

  test 'authorized_by_any_roles?() should return false if given a denied role' do
    @collection.denied_roles << roles(:users)
    assert !@collection.authorized_by_any_roles?([roles(:users)])
  end

  test 'authorized_by_any_roles?() should return true if given an allowed role
  and a denied role' do
    @collection.allowed_roles << roles(:cellists)
    @collection.denied_roles << roles(:users)
    assert @collection.authorized_by_any_roles?([roles(:users), roles(:cellists)])
  end

  # authorized_by_role?()

  test 'authorized_by_role?() should return false if the given role is denied' do
    @collection.denied_roles << roles(:admins)
    assert !@collection.authorized_by_role?(roles(:admins))
  end

  test 'authorized_by_role?() should return false if the given role is not in
  the list of allowed roles' do
    @collection.allowed_roles << roles(:admins)
    assert !@collection.authorized_by_role?(roles(:users))
  end

  test 'authorized_by_role?() should return true if the given role is explicitly
  allowed' do
    @collection.allowed_roles << roles(:admins)
    assert @collection.authorized_by_role?(roles(:admins))
  end

  test 'authorized_by_role?() should return true if there are no allowed roles
  and the given role is not explicitly denied' do
    @collection.denied_roles << roles(:admins)
    assert @collection.authorized_by_role?(roles(:users))
  end

end
