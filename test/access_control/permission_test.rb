require 'test_helper'

class PermissionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test 'name() should return the name' do
    p = Permission.new(key: Permission::Permissions::CREATE_USER)
    assert_equal 'Create User', p.name
  end
end
