require 'test_helper'

class AuthorizableByHostTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:compound_object)
  end

  # authorized_by_any_host_groups?()

  test 'authorized_by_any_host_groups?() returns true if the instance has no
  allowed or denied host groups' do
    assert @collection.authorized_by_any_host_groups?([])
    assert @collection.authorized_by_any_host_groups?([host_groups(:red)])
  end

  test 'authorized_by_any_host_groups?() returns true if the instance has a
  non-matching denied host group' do
    @collection.denied_host_groups << host_groups(:yellow)
    assert @collection.authorized_by_any_host_groups?([host_groups(:red)])
  end

  test 'authorized_by_any_host_groups?() returns false if given no host groups
  but the instance has allowed host groups' do
    @collection.allowed_host_groups << host_groups(:yellow)
    assert !@collection.authorized_by_any_host_groups?([])
  end

  test 'authorized_by_any_host_groups?() returns false if given a denied host
  group' do
    @collection.denied_host_groups << host_groups(:yellow)
    assert !@collection.authorized_by_any_host_groups?([host_groups(:yellow)])
  end

  test 'authorized_by_any_host_groups?() returns true if given an allowed host
  group and a denied host group' do
    g1 = host_groups(:blue)
    g2 = host_groups(:yellow)
    @collection.allowed_host_groups << g1
    @collection.denied_host_groups << g2
    assert @collection.authorized_by_any_host_groups?([g1, g2])
  end

  # authorized_by_host_group?()

  test 'authorized_by_host_group?() returns false if the given host group is
  denied' do
    @collection.denied_host_groups << host_groups(:red)
    assert !@collection.authorized_by_host_group?(host_groups(:red))
  end

  test 'authorized_by_host_group?() returns false if the given host group is
  not in the list of allowed host groups' do
    @collection.allowed_host_groups << host_groups(:red)
    assert !@collection.authorized_by_host_group?(host_groups(:blue))
  end

  test 'authorized_by_host_group?() returns true if the given host group is
  explicitly allowed' do
    @collection.allowed_host_groups << host_groups(:red)
    assert @collection.authorized_by_host_group?(host_groups(:red))
  end

  test 'authorized_by_host_group?() returns true if there are no allowed host
  groups and the given host group is not explicitly denied' do
    @collection.denied_host_groups << host_groups(:red)
    assert @collection.authorized_by_host_group?(host_groups(:blue))
  end

end
