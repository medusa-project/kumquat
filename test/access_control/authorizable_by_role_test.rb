require 'test_helper'

class AuthorizableByRoleTest < ActiveSupport::TestCase

  # authorized_by_any_roles?()

  test 'authorized_by_any_roles?() should return false if given no roles but
  the instance has allowed roles' do
    col = collections(:collection1)
    col.allowed_roles << roles(:users)
    assert !col.authorized_by_any_roles?([])
  end

  test 'authorized_by_any_roles?() should return false if given a denied role' do
    col = collections(:collection1)
    col.denied_roles << roles(:users)
    assert !col.authorized_by_any_roles?([roles(:users)])
  end

  test 'authorized_by_any_roles?() should return true if given an allowed role
  and a denied role' do
    col = collections(:collection1)
    col.allowed_roles << roles(:cellists)
    col.denied_roles << roles(:users)
    assert col.authorized_by_any_roles?([roles(:users), roles(:cellists)])
  end

  # authorized_by_role?()

  test 'authorized_by_role?() should return false if the given role is denied' do
    col = collections(:collection1)
    col.denied_roles << roles(:admins)
    assert !col.authorized_by_role?(roles(:admins))
  end

  test 'authorized_by_role?() should return false if the given role is not in
  the list of allowed roles' do
    col = collections(:collection1)
    col.allowed_roles << roles(:admins)
    assert !col.authorized_by_role?(roles(:users))
  end

  test 'authorized_by_role?() should return true if the given role is explicitly
  allowed' do
    col = collections(:collection1)
    col.allowed_roles << roles(:admins)
    assert col.authorized_by_role?(roles(:admins))
  end

  test 'authorized_by_role?() should return true if there are no allowed roles
  and the given role is not explicitly denied' do
    col = collections(:collection1)
    col.denied_roles << roles(:admins)
    assert col.authorized_by_role?(roles(:users))
  end

end
