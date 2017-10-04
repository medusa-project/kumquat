require 'test_helper'

class MetadataProfilesControllerTest < ActionDispatch::IntegrationTest

  setup do
    sign_in_as(users(:admin))
  end

  # clone()

  test 'clone() clones the profile' do
    profile = metadata_profiles(:unused)
    patch "/admin/metadata-profiles/#{profile.id}/clone"
    assert_not_nil MetadataProfile.find_by_name("Clone of #{profile.name}")
  end

  test 'clone() redirects to the cloned profile' do
    profile = metadata_profiles(:unused)
    patch "/admin/metadata-profiles/#{profile.id}/clone"
    assert_redirected_to admin_metadata_profile_path(
                             MetadataProfile.find_by_name("Clone of #{profile.name}"))
  end

  # create()

  test 'create() creates a profile' do
    post '/admin/metadata-profiles', {
        xhr: true,
        params: {
            metadata_profile: {
                name: 'cats'
            }
        }
    }

    assert_not_nil MetadataProfile.find_by_name('cats')
  end

  # delete_elements()

  test 'delete_elements() deletes the given elements' do
    profile = metadata_profiles(:unused)
    profile.add_default_elements
    count = profile.elements.count
    assert count > 0

    post "/admin/metadata-profiles/#{profile.id}/delete-elements", {
        params: {
            elements: [
                profile.elements.where(name: 'title').first.id
            ]
        }
    }

    profile.reload
    assert_equal count - 1, profile.elements.count
  end

  # destroy()

  test 'destroy() destroys the profile' do
    profile = metadata_profiles(:unused)
    delete "/admin/metadata-profiles/#{profile.id}"
    assert_raises ActiveRecord::RecordNotFound do
      MetadataProfile.find(profile.id)
    end
  end

  test 'destroy() returns HTTP 302 for an existing profile' do
    profile = metadata_profiles(:unused)
    delete "/admin/metadata-profiles/#{profile.id}"
    assert_redirected_to admin_metadata_profiles_path
  end

  # import()

  test 'import() imports a profile' do
    skip # TODO: write this
  end

  # index()

  test 'index() should return HTTP 200' do
    get '/admin/metadata-profiles'
    assert_response :ok
  end

  # show()

  test 'show() should return HTTP 200 for a present profile' do
    profile = metadata_profiles(:default_metadata_profile)
    get "/admin/metadata-profiles/#{profile.id}"
    assert_response :ok
  end

  # update()

  test 'update() should update a profile' do
    profile = metadata_profiles(:unused)

    patch "/admin/metadata-profiles/#{profile.id}", {
        params: {
            metadata_profile: {
                name: 'cats'
            }
        }
    }

    profile.reload
    assert_equal 'cats', profile.name
  end

end

