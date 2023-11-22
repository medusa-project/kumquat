require 'test_helper'

class CollectionPolicyTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:compound_object)
    @context    = RequestContext.new(client_hostname: "localhost",
                                     client_ip:       "127.0.0.1")
  end

  # iiif_presentation?()

  test "iiif_presentation?() does not authorize non-Medusa admins to restricted
  collections" do
    @collection.update!(restricted: true)
    assert !CollectionPolicy.new(@context, @collection).iiif_presentation?
  end

  test "iiif_presentation?() does not authorize non-Medusa admins to non-publicly-accessible
  collections" do
    @collection.update!(published_in_dls: false)
    assert !CollectionPolicy.new(@context, @collection).iiif_presentation?
  end

  test "iiif_presentation?() does not authorize non-Medusa admins to host group-restricted
  collections" do
    @collection.denied_host_groups << host_groups(:localhost)
    @collection.save!
    assert !CollectionPolicy.new(@context, @collection).iiif_presentation?
  end

  test "iiif_presentation?() authorizes unrestricted collections" do
    assert CollectionPolicy.new(@context, @collection).iiif_presentation?
  end

  # iiif_presentation_list?()

  test "iiif_presentation_list?() authorizes everyone" do
    assert CollectionPolicy.new(@context, @collection).iiif_presentation_list?
  end

  # index?()

  test "index?() authorizes everyone" do
    assert CollectionPolicy.new(@context, @collection).index?
  end

  # show?()

  test "show?() does not authorize non-Medusa admins to restricted
  collections" do
    @collection.update!(restricted: true)
    assert !CollectionPolicy.new(@context, @collection).show?
  end

  test "show?() does not authorize non-Medusa admins to non-publicly-accessible
  collections" do
    @collection.update!(published_in_dls: false)
    assert !CollectionPolicy.new(@context, @collection).show?
  end

  test "show?() does not authorize non-Medusa admins to host group-restricted
  collections" do
    @collection.denied_host_groups << host_groups(:localhost)
    @collection.save!
    assert !CollectionPolicy.new(@context, @collection).show?
  end

  test "show?() authorizes unrestricted collections" do
    assert CollectionPolicy.new(@context, @collection).show?
  end

  # show_contentdm?()

  test "show_contentdm?() authorizes everyone" do
    assert CollectionPolicy.new(@context, @collection).show_contentdm?
  end

end
