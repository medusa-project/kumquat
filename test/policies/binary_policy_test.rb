require 'test_helper'

class BinaryPolicyTest < ActiveSupport::TestCase

  setup do
    @binary  = binaries(:compound_object_1001_access)
    @context = RequestContext.new(client_ip:       "127.0.0.1",
                                  client_hostname: "example.org")
  end

  # object?()

  test "object?() does not authorize non-public binaries to logged-out users" do
    @binary.update!(public: false)
    assert !BinaryPolicy.new(@context, @binary).object?
  end

  test "object?() does not authorize non-public binaries to logged-in,
  non-Medusa users" do
    @context = RequestContext.new(user: users(:normal))
    @binary.update!(public: false)
    assert !BinaryPolicy.new(@context, @binary).object?
  end

  test "object?() does not authorize binaries whose owning item is not
  authorized" do
    @binary.item.update!(published: false)
    assert !BinaryPolicy.new(@context, @binary).object?
  end

  test "object?() does not authorize binaries whose owning collection is not
  authorized" do
    @binary.item.collection.update!(published_in_dls: false)
    assert !BinaryPolicy.new(@context, @binary).object?
  end

  test "object?() authorizes public binaries" do
    assert BinaryPolicy.new(@context, @binary).object?
  end

  # show?()

  test "show?() does not authorize non-public binaries to logged-out users" do
    @binary.update!(public: false)
    assert !BinaryPolicy.new(@context, @binary).show?
  end

  test "show?() does not authorize non-public binaries to logged-in,
  non-Medusa users" do
    @context = RequestContext.new(user: users(:normal))
    @binary.update!(public: false)
    assert !BinaryPolicy.new(@context, @binary).show?
  end

  test "show?() does not authorize binaries whose owning item is not
  authorized" do
    @binary.item.update!(published: false)
    assert !BinaryPolicy.new(@context, @binary).show?
  end

  test "show?() does not authorize binaries whose owning collection is not
  authorized" do
    @binary.item.collection.update!(published_in_dls: false)
    assert !BinaryPolicy.new(@context, @binary).show?
  end

  test "show?() authorizes public binaries" do
    assert BinaryPolicy.new(@context, @binary).show?
  end

  # stream?()

  test "stream?() does not authorize non-public binaries to logged-out users" do
    @binary.update!(public: false)
    assert !BinaryPolicy.new(@context, @binary).stream?
  end

  test "stream?() does not authorize non-public binaries to logged-in,
  non-Medusa users" do
    @context = RequestContext.new(user: users(:normal))
    @binary.update!(public: false)
    assert !BinaryPolicy.new(@context, @binary).stream?
  end

  test "stream?() does not authorize binaries whose owning item is not
  authorized" do
    @binary.item.update!(published: false)
    assert !BinaryPolicy.new(@context, @binary).stream?
  end

  test "stream?() does not authorize binaries whose owning collection is not
  authorized" do
    @binary.item.collection.update!(published_in_dls: false)
    assert !BinaryPolicy.new(@context, @binary).stream?
  end

  test "stream?() authorizes public binaries" do
    assert BinaryPolicy.new(@context, @binary).stream?
  end

end
