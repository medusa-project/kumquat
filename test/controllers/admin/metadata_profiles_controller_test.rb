require 'test_helper'

module Admin

  class MetadataProfilesControllerTest < ActionDispatch::IntegrationTest

    # clone()

    test "clone() redirects to sign-in page for signed-out users" do
      profile = metadata_profiles(:unused)
      patch admin_metadata_profile_clone_path(profile)
      assert_redirected_to signin_path
    end

    test "clone() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      profile = metadata_profiles(:unused)
      patch admin_metadata_profile_clone_path(profile)
      assert_response :forbidden
    end

    test "clone() redirects to the cloned profile" do
      sign_in_as(users(:medusa_admin))
      profile = metadata_profiles(:unused)
      patch admin_metadata_profile_clone_path(profile)
      assert_redirected_to admin_metadata_profile_path(
                               MetadataProfile.find_by_name("Clone of #{profile.name}"))
    end

    test "clone() clones the profile" do
      sign_in_as(users(:medusa_admin))
      profile = metadata_profiles(:unused)
      patch admin_metadata_profile_clone_path(profile)
      assert_not_nil MetadataProfile.find_by_name("Clone of #{profile.name}")
    end

    # create()

    test "create() redirects to sign-in page for signed-out users" do
      post admin_metadata_profiles_path
      assert_redirected_to signin_path
    end

    test 'create() returns HTTP 403 for unauthorized users' do
      sign_in_as(users(:medusa_user))
      post admin_metadata_profiles_path,
           xhr: true,
           params: {
             metadata_profile: {
               name: 'cats'
             }
           }
      assert_response :forbidden
    end

    test "create() creates a profile" do
      sign_in_as(users(:medusa_admin))
      post admin_metadata_profiles_path,
           xhr: true,
           params: {
             metadata_profile: {
               name: 'cats'
             }
           }
      assert_not_nil MetadataProfile.find_by_name('cats')
    end

    # delete_elements()

    test "delete_elements() redirects to sign-in page for signed-out users" do
      profile = metadata_profiles(:unused)
      post admin_metadata_profile_delete_elements_path(profile)
      assert_redirected_to signin_path
    end

    test "delete_elements() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:medusa_user))
      profile = metadata_profiles(:unused)
      post admin_metadata_profile_delete_elements_path(profile)
      assert_response :forbidden
    end

    test "delete_elements() redirects upon success" do
      sign_in_as(users(:medusa_admin))
      profile = metadata_profiles(:unused)
      post admin_metadata_profile_delete_elements_path(profile)
      assert_redirected_to admin_metadata_profile_path(profile)
    end

    test "delete_elements() deletes the given elements" do
      sign_in_as(users(:medusa_admin))
      profile = metadata_profiles(:unused)
      profile.add_default_elements
      count = profile.elements.count
      assert count > 0

      post admin_metadata_profile_delete_elements_path(profile),
           params: {
             elements: [
               profile.elements.where(name: 'title').first.id
             ]
           }

      profile.reload
      assert_equal count - 1, profile.elements.count
    end

    # destroy()

    test "destroy() redirects to sign-in page for signed-out users" do
      profile = metadata_profiles(:unused)
      delete admin_metadata_profile_path(profile)
      assert_redirected_to signin_path
    end

    test 'destroy() returns HTTP 403 for insufficient privileges' do
      sign_in_as(users(:medusa_user))
      profile = metadata_profiles(:unused)
      delete admin_metadata_profile_path(profile)
      assert_response :forbidden
    end

    test "destroy() redirects upon success" do
      sign_in_as(users(:medusa_admin))
      profile = metadata_profiles(:unused)
      delete admin_metadata_profile_path(profile)
      assert_redirected_to admin_metadata_profiles_path
    end

    test "destroy() destroys the profile" do
      sign_in_as(users(:medusa_admin))
      profile = metadata_profiles(:unused)
      delete admin_metadata_profile_path(profile)
      assert_raises ActiveRecord::RecordNotFound do
        MetadataProfile.find(profile.id)
      end
    end

    # import()

    test "import() redirects to sign-in page for signed-out users" do
      post admin_metadata_profile_import_path,
           params: {
             metadata_profile: nil
           }
      assert_redirected_to signin_path
    end

    test 'import() returns HTTP 403 for insufficient privileges' do
      sign_in_as(users(:medusa_user))
      post admin_metadata_profile_import_path,
           params: {
             metadata_profile: nil
           }
      assert_response :forbidden
    end

    test "import() redirects upon success" do
      sign_in_as(users(:medusa_admin))
      post admin_metadata_profile_import_path,
           params: {
             metadata_profile: nil
           }
      assert_redirected_to admin_metadata_profiles_path
    end

    test "import() imports a profile" do
      skip # TODO: write this
      sign_in_as(users(:medusa_admin))
    end

    # index()

    test "index() redirects to sign-in page for signed-out users" do
      post admin_metadata_profiles_path
      assert_redirected_to signin_path
    end

    test "index() returns HTTP 403 for insufficient privileges" do
      sign_in_as(users(:medusa_user))
      get admin_metadata_profiles_path
      assert_response :forbidden
    end

    test "index() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      get admin_metadata_profiles_path
      assert_response :ok
    end

    # show()

    test "show() redirects to sign-in page for signed-out users" do
      profile = metadata_profiles(:default)
      get admin_metadata_profile_path(profile)
      assert_redirected_to signin_path
    end

    test 'show() returns HTTP 403 for insufficient privileges' do
      sign_in_as(users(:medusa_user))
      profile = metadata_profiles(:default)
      get admin_metadata_profile_path(profile)
      assert_response :forbidden
    end

    test "show() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      profile = metadata_profiles(:default)
      get admin_metadata_profile_path(profile)
      assert_response :ok
    end

    # update()

    test "update() redirects to sign-in page for signed-out users" do
      profile = metadata_profiles(:default)
      patch admin_metadata_profile_path(profile)
      assert_redirected_to signin_path
    end

    test "update() returns HTTP 403 for insufficient privileges" do
      sign_in_as(users(:medusa_user))
      profile = metadata_profiles(:unused)

      patch admin_metadata_profile_path(profile),
            params: {
              metadata_profile: {
                name: 'cats'
              }
            }
      assert_response :forbidden
    end

    test "update() redirects upon success" do
      sign_in_as(users(:medusa_admin))
      profile = metadata_profiles(:default)
      patch admin_metadata_profile_path(profile)
      assert_redirected_to admin_metadata_profile_path(profile)
    end

    test "update() updates a profile" do
      sign_in_as(users(:medusa_admin))
      profile = metadata_profiles(:unused)

      patch admin_metadata_profile_path(profile),
            params: {
              metadata_profile: {
                name: 'cats'
              }
            }

      profile.reload
      assert_equal 'cats', profile.name
    end

  end

end
