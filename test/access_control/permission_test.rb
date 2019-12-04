require 'test_helper'

class PermissionTest < ActiveSupport::TestCase

  test 'name() should return the name' do
    p = Permission.new(key: Permissions::MODIFY_USERS)
    assert_equal 'Modify Users', p.name
  end

end
