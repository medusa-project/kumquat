require 'test_helper'

class PermissionsTest < ActiveSupport::TestCase

  test 'all() returns all permissions' do
    assert_equal 5, Permissions.all.length
  end

end
