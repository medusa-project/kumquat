require 'test_helper'

class RoleTest < ActiveSupport::TestCase

  test 'all_matching_host_or_ip() should return an empty set when there are no matches' do
    role1 = roles(:admins)
    role1.hosts.build(pattern: '*.cats.org')
    role1.hosts.build(pattern: '202.202.*')
    role1.save!

    role1 = roles(:users)
    role1.hosts.build(pattern: '*.dogs.org')
    role1.hosts.build(pattern: '12.12.*')
    role1.save!

    assert_empty Role.all_matching_hostname_or_ip('example.org', '123.123.123.123')
  end

  test 'all_matching_host_or_ip() should return roles with matching hostnames' do
    role1 = roles(:admins)
    role1.hosts.build(pattern: '*.cats.org')
    role1.hosts.build(pattern: '202.202.*')
    role1.save!

    role1 = roles(:users)
    role1.hosts.build(pattern: '*.dogs.org')
    role1.hosts.build(pattern: '12.12.*')
    role1.save!

    assert_equal 1, Role.all_matching_hostname_or_ip('cats.org', '123.123.123.123').length
  end

  test 'all_matching_host_or_ip() should return roles with matching IP addresses' do
    role1 = roles(:admins)
    role1.hosts.build(pattern: '*.cats.org')
    role1.hosts.build(pattern: '202.202.*')
    role1.save!

    role1 = roles(:users)
    role1.hosts.build(pattern: '*.dogs.org')
    role1.hosts.build(pattern: '12.12.*')
    role1.save!

    assert_equal 1, Role.all_matching_hostname_or_ip('example.org', '12.12.12.12').length
  end

end
