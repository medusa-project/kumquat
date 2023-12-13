require 'test_helper'

class ItemPolicyTest < ActiveSupport::TestCase

  setup do
    @item    = items(:compound_object_1001)
    @context = RequestContext.new(client_ip:       "127.0.0.1",
                                  client_hostname: "example.org")
  end

  # binary?()

  test "binary?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).binary?
  end

  test "binary?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).binary?
  end

  test "binary?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).binary?
  end

  test "binary?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).binary?
  end

  test "binary?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).binary?
  end

  test "binary?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).binary?
  end

  test "binary?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).binary?
  end

  test "binary?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).binary?
  end

  test "binary?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).binary?
  end

  # iiif_annotation_list?()

  test "iiif_annotation_list?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).iiif_annotation_list?
  end

  test "iiif_annotation_list?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_annotation_list?
  end

  test "iiif_annotation_list?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).iiif_annotation_list?
  end

  test "iiif_annotation_list?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_annotation_list?
  end

  test "iiif_annotation_list?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_annotation_list?
  end

  test "iiif_annotation_list?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_annotation_list?
  end

  test "iiif_annotation_list?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).iiif_annotation_list?
  end

  test "iiif_annotation_list?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).iiif_annotation_list?
  end

  test "iiif_annotation_list?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).iiif_annotation_list?
  end

  # iiif_canvas?()

  test "iiif_canvas?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).iiif_canvas?
  end

  test "iiif_canvas?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_canvas?
  end

  test "iiif_canvas?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).iiif_canvas?
  end

  test "iiif_canvas?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_canvas?
  end

  test "iiif_canvas?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_canvas?
  end

  test "iiif_canvas?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_canvas?
  end

  test "iiif_canvas?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).iiif_canvas?
  end

  test "iiif_canvas?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).iiif_canvas?
  end

  test "iiif_canvas?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).iiif_canvas?
  end

  # iiif_image_resource?()

  test "iiif_image_resource?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).iiif_image_resource?
  end

  test "iiif_image_resource?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_image_resource?
  end

  test "iiif_image_resource?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).iiif_image_resource?
  end

  test "iiif_image_resource?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_image_resource?
  end

  test "iiif_image_resource?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_image_resource?
  end

  test "iiif_image_resource?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_image_resource?
  end

  test "iiif_image_resource?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).iiif_image_resource?
  end

  test "iiif_image_resource?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).iiif_image_resource?
  end

  test "iiif_image_resource?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).iiif_image_resource?
  end

  # iiif_layer?()

  test "iiif_layer?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).iiif_layer?
  end

  test "iiif_layer?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_layer?
  end

  test "iiif_layer?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).iiif_layer?
  end

  test "iiif_layer?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_layer?
  end

  test "iiif_layer?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_layer?
  end

  test "iiif_layer?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_layer?
  end

  test "iiif_layer?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).iiif_layer?
  end

  test "iiif_layer?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).iiif_layer?
  end

  test "iiif_layer?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).iiif_layer?
  end

  # iiif_manifest?()

  test "iiif_manifest?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).iiif_manifest?
  end

  test "iiif_manifest?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_manifest?
  end

  test "iiif_manifest?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).iiif_manifest?
  end

  test "iiif_manifest?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_manifest?
  end

  test "iiif_manifest?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_manifest?
  end

  test "iiif_manifest?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_manifest?
  end

  test "iiif_manifest?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).iiif_manifest?
  end

  test "iiif_manifest?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).iiif_manifest?
  end

  test "iiif_manifest?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).iiif_manifest?
  end

  # iiif_media_sequence?()

  test "iiif_media_sequence?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).iiif_media_sequence?
  end

  test "iiif_media_sequence?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_media_sequence?
  end

  test "iiif_media_sequence?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).iiif_media_sequence?
  end

  test "iiif_media_sequence?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_media_sequence?
  end

  test "iiif_media_sequence?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_media_sequence?
  end

  test "iiif_media_sequence?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_media_sequence?
  end

  test "iiif_media_sequence?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).iiif_media_sequence?
  end

  test "iiif_media_sequence?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).iiif_media_sequence?
  end

  test "iiif_media_sequence?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).iiif_media_sequence?
  end

  # iiif_range?()

  test "iiif_range?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).iiif_range?
  end

  test "iiif_range?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_range?
  end

  test "iiif_range?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).iiif_range?
  end

  test "iiif_range?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_range?
  end

  test "iiif_range?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_range?
  end

  test "iiif_range?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_range?
  end

  test "iiif_range?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).iiif_range?
  end

  test "iiif_range?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).iiif_range?
  end

  test "iiif_range?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).iiif_range?
  end

  # iiif_search?()

  test "iiif_search?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).iiif_search?
  end

  test "iiif_search?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_search?
  end

  test "iiif_search?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).iiif_search?
  end

  test "iiif_search?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_search?
  end

  test "iiif_search?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_search?
  end

  test "iiif_search?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_search?
  end

  test "iiif_search?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).iiif_search?
  end

  test "iiif_search?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).iiif_search?
  end

  test "iiif_search?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).iiif_search?
  end

  # iiif_sequence?()

  test "iiif_sequence?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).iiif_sequence?
  end

  test "iiif_sequence?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_sequence?
  end

  test "iiif_sequence?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).iiif_sequence?
  end

  test "iiif_sequence?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).iiif_sequence?
  end

  test "iiif_sequence?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_sequence?
  end

  test "iiif_sequence?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).iiif_sequence?
  end

  test "iiif_sequence?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).iiif_sequence?
  end

  test "iiif_sequence?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).iiif_sequence?
  end

  test "iiif_sequence?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).iiif_sequence?
  end

  # index?()

  test "index?() allows everybody" do
    assert ItemPolicy.new(@context, @item).index?
  end

  # item_tree_node?()

  test "item_tree_node?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).item_tree_node?
  end

  test "item_tree_node?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).item_tree_node?
  end

  test "item_tree_node?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).item_tree_node?
  end

  test "item_tree_node?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).item_tree_node?
  end

  test "item_tree_node?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).item_tree_node?
  end

  test "item_tree_node?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).item_tree_node?
  end

  test "item_tree_node?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).item_tree_node?
  end

  test "item_tree_node?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).item_tree_node?
  end

  test "item_tree_node?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).item_tree_node?
  end

  # show?()

  test "show?() does not authorize items whose collections are restricted" do
    @item.collection.update!(restricted: true)
    assert !ItemPolicy.new(@context, @item).show?
  end

  test "show?() does not authorize items that aren't allowing the current
  NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: "someoneelse", expires: Time.now.to_i + 1.year }]
    @item.save!
    assert !ItemPolicy.new(@context, @item).show?
  end

  test "show?() authorizes items that are allowing the current NetID" do
    @context.user        = users(:normal)
    @item.allowed_netids = [{ netid: @context.user.username, expires: Time.now.to_i + 1.year }]
    @item.save!
    assert ItemPolicy.new(@context, @item).show?
  end

  test "show?() does not authorize items that are not allowing any of the
  client's host groups" do
    @item.allowed_host_groups << host_groups(:yellow)
    @item.save!
    assert !ItemPolicy.new(@context, @item).show?
  end

  test "show?() does not authorize unpublished items" do
    @item.update!(published: false)
    assert !ItemPolicy.new(@context, @item).show?
  end

  test "show?() does not authorize items whose parent item is unpublished" do
    @item = items(:compound_object_1002_page1)
    @item.parent.update!(published: false)
    assert !ItemPolicy.new(@context, @item).show?
  end

  test "show?() does not authorize items whose owning collection is
  unpublished" do
    @item.collection.update!(published_in_dls: false)
    assert !ItemPolicy.new(@context, @item).show?
  end

  test "show?() does not authorize items whose owning collection is private
  in Medusa" do
    @item.collection.update!(public_in_medusa: false)
    assert !ItemPolicy.new(@context, @item).show?
  end

  test "show?() authorizes public items" do
    assert ItemPolicy.new(@context, @item).show?
  end

  # tree?()

  test "tree?() allows everybody" do
    assert ItemPolicy.new(@context, @item).tree?
  end

  # tree_data?()

  test "tree_data?() allows everybody" do
    assert ItemPolicy.new(@context, @item).tree_data?
  end

end
