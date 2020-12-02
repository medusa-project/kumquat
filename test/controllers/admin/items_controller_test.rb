require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @item = items(:compound_object_1002)
  end

  # publicize_child_binaries()

  test "publicize_child_binaries() redirects to sign-in page for signed-out users" do
    post admin_collection_item_publicize_child_binaries_path(@item.collection, @item)
    assert_redirected_to signin_path
  end

  test 'publicize_child_binaries() publicizes all child binaries' do
    sign_in_as(users(:admin))

    # unpublicize all child items' binaries
    binaries = @item.items.map{ |child| child.binaries }.flatten
    binaries.each{ |binary| binary.update!(public: false) }

    post admin_collection_item_publicize_child_binaries_path(@item.collection, @item)

    # test that they have been publicized
    binaries.each do |binary|
      binary.reload
      assert binary.public
    end
  end

  test 'publicize_child_binaries() redirects back upon success' do
    sign_in_as(users(:admin))
    post admin_collection_item_publicize_child_binaries_path(@item.collection, @item)
    assert_redirected_to admin_collection_item_path(@item.collection, @item)
  end

  # unpublicize_child_binaries()

  test "unpublicize_child_binaries() redirects to sign-in page for signed-out users" do
    post admin_collection_item_unpublicize_child_binaries_path(@item.collection, @item)
    assert_redirected_to signin_path
  end

  test 'unpublicize_child_binaries() unpublicizes all child binaries' do
    sign_in_as(users(:admin))

    # verify that all child items' binaries are public
    binaries = @item.items.map{ |child| child.binaries }.flatten
    binaries.each{ |binary| assert binary.public }

    post admin_collection_item_unpublicize_child_binaries_path(@item.collection, @item)

    # test that they have been unpublicized
    binaries.each do |binary|
      binary.reload
      assert !binary.public
    end
  end

  test 'unpublicize_child_binaries() redirects back upon success' do
    sign_in_as(users(:admin))
    post admin_collection_item_unpublicize_child_binaries_path(@item.collection, @item)
    assert_redirected_to admin_collection_item_path(@item.collection, @item)
  end

end

