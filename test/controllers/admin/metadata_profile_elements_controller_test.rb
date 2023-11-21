require 'test_helper'

module Admin

  class MetadataProfileElementsControllerTest < ActionDispatch::IntegrationTest

    setup do
      @element = metadata_profile_elements(:compound_object_1001_title)
      @profile = @element.metadata_profile
    end

    # create()

    test "create() redirects to sign-in page for signed-out users" do
      post admin_metadata_profile_elements_path(@profile)
      assert_redirected_to signin_path
    end

    test 'create() returns HTTP 403 for unauthorized users' do
      sign_in_as(users(:medusa_user))
      post admin_metadata_profile_elements_path(@profile),
           xhr: true,
           params: {
             metadata_profile_element: {
               metadata_profile_id: @profile.id,
               name:  'cats',
               index: 0,
               vocabulary_ids: [
                 vocabularies(:uncontrolled).id
               ]
             }
           }
      assert_response :forbidden
    end

    test "create() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      post admin_metadata_profile_elements_path(@profile),
           xhr: true,
           params: {
             metadata_profile_element: {
               metadata_profile_id: @profile.id,
               name:  'cats',
               index: 0,
               vocabulary_ids: [
                 vocabularies(:uncontrolled).id
               ]
             }
           }
      assert_response :ok
    end

    test "create() creates an element" do
      sign_in_as(users(:medusa_admin))
      assert_difference "MetadataProfileElement.count" do
      post admin_metadata_profile_elements_path(@profile),
           xhr: true,
           params: {
             metadata_profile_element: {
               metadata_profile_id: @profile.id,
               name:  'cats',
               index: 0,
               vocabulary_ids: [
                 vocabularies(:uncontrolled).id
               ]
             }
           }
      end
    end

    # destroy()

    test "destroy() redirects to sign-in page for signed-out users" do
      delete admin_metadata_profile_element_path(@element)
      assert_redirected_to signin_path
    end

    test 'destroy() returns HTTP 403 for insufficient privileges' do
      sign_in_as(users(:medusa_user))
      delete admin_metadata_profile_element_path(@element)
      assert_response :forbidden
    end

    test "destroy() redirects upon success" do
      sign_in_as(users(:medusa_admin))

      delete admin_metadata_profile_element_path(@element)
      assert_redirected_to admin_metadata_profiles_path
    end

    test "destroy() destroys the element" do
      sign_in_as(users(:medusa_admin))

      delete admin_metadata_profile_element_path(@element)
      assert_raises ActiveRecord::RecordNotFound do
        @element.reload
      end
    end

    # edit()

    test "edit() redirects to sign-in page for signed-out users" do
      get edit_admin_metadata_profile_element_path(@element), xhr: true
      assert_redirected_to signin_path
    end

    test "edit() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get edit_admin_metadata_profile_element_path(@element), xhr: true
      assert_response :forbidden
    end

    test "edit() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      get edit_admin_metadata_profile_element_path(@element), xhr: true
      assert_response :ok
    end

    # update()

    test "update() redirects to sign-in page for signed-out users" do
      patch admin_metadata_profile_element_path(@element)
      assert_redirected_to signin_path
    end

    test "update() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_metadata_profile_element_path(@element),
            xhr: true,
            params: {
              metadata_profile_element: {
                name: "New Name"
              }
            }
      assert_response :forbidden
    end

    test "update() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      patch admin_metadata_profile_element_path(@element),
            xhr: true,
            params: {
              metadata_profile_element: {
                name: "New Name"
              }
            }
      assert_response :ok
    end

  end

end
