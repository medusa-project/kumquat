require 'test_helper'

class PermissionsTest < ActiveSupport::TestCase

  test 'all() returns all permissions' do
    assert Permissions.all.length > 5
  end

end
