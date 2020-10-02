require 'test_helper'

class PackageProfileTest < ActiveSupport::TestCase

  # all

  test 'all() returns the correct profiles' do
    all = PackageProfile.all
    assert_equal 4, all.length

    # free-form profile
    assert_equal 0, all[0].id
    assert_equal 'Free-Form', all[0].name

    # compound object profile
    assert_equal 1, all[1].id
    assert_equal 'Compound Object', all[1].name

    # single-item object profile
    assert_equal 2, all[2].id
    assert_equal 'Single-Item Object', all[2].name

    # mixed media profile
    assert_equal 3, all[3].id
    assert_equal 'Mixed Media', all[3].name
  end

  # find

  test 'find() returns the correct profile' do
    assert_not_nil PackageProfile.find(1)
    assert_nil PackageProfile.find(27)
  end

  # ==(obj)

  test '==() works properly' do
    p1 = PackageProfile.new
    p2 = PackageProfile.new
    assert p1 == p2

    p1 = PackageProfile.new
    p1.id = 3
    p2 = PackageProfile.new
    p2.id = 3
    assert p1 == p2

    p1 = PackageProfile.new
    p1.id = 3
    p2 = PackageProfile.new
    p2.id = 4
    assert !(p1 == p2)
  end

  # parent_id_from_medusa()

  test 'parent_id_from_medusa() raises an error if no ID is provided' do
    assert_raises ArgumentError do
      PackageProfile::FREE_FORM_PROFILE.parent_id_from_medusa(nil)
    end
  end

  # parent_id_from_medusa() (with free-form profile)

  test 'parent_id_from_medusa() with the free-form profile returns nil with
        top-level items' do
    item = '7351760f-4b7b-5a6c-6dda-f5a92562b008'
    assert_nil PackageProfile::FREE_FORM_PROFILE.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa() with the free-form profile returns the parent
        UUID' do
    page            = '39582239-4307-1cc6-c9c6-074516fd7635'
    expected_parent = '7351760f-4b7b-5a6c-6dda-f5a92562b008'
    assert_equal expected_parent,
                 PackageProfile::FREE_FORM_PROFILE.parent_id_from_medusa(page)
  end

  # parent_id_from_medusa() (with single-item object profile)

  test 'parent_id_from_medusa() with the single item object profile returns nil
        with items' do
    item = 'cbbc845c-167a-60df-df6e-41a249a43b7c'
    assert_nil PackageProfile::SINGLE_ITEM_OBJECT_PROFILE.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa() with the single item object profile returns nil
        for non-item content' do
    bogus = '7a046e7d-dd12-9052-76be-3de2e147b5e0'
    assert_nil PackageProfile::SINGLE_ITEM_OBJECT_PROFILE.parent_id_from_medusa(bogus)
  end

  # parent_id_from_medusa() (with compound object profile)

  test 'parent_id_from_medusa() with the compound object profile returns nil
        with top-level items' do
    item = '60d89337-6157-981e-6994-ec07b9572015'
    assert_nil PackageProfile::COMPOUND_OBJECT_PROFILE.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa() with the compound object profile returns the
        parent UUID with pages' do
    page            = '8ec70c33-75c9-4ba5-cd21-54a1211e5375'
    expected_parent = '21353276-887c-0f2b-25a0-ed444003303f'
    assert_equal expected_parent,
                 PackageProfile::COMPOUND_OBJECT_PROFILE.parent_id_from_medusa(page)
  end

  test 'parent_id_from_medusa() with the compound object profile returns nil
        for non-item content' do
    bogus = '7a046e7d-dd12-9052-76be-3de2e147b5e0'
    assert_nil PackageProfile::COMPOUND_OBJECT_PROFILE.parent_id_from_medusa(bogus)
  end

  # parent_id_from_medusa() (with mixed media profile)

  test 'parent_id_from_medusa() with the mixed media profile returns nil with
        top-level items' do
    item = '1db0b737-83ea-5587-d910-06c22eb6c74c'
    assert_nil MedusaMixedMediaIngester.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa() with the mixed media profile returns the
        parent UUID with pages' do
    page            = '718035e2-09bb-ed67-ccdc-05ecdf99d999'
    expected_parent = '1db0b737-83ea-5587-d910-06c22eb6c74c'
    assert_equal expected_parent,
                 MedusaMixedMediaIngester.parent_id_from_medusa(page)
  end

  test 'parent_id_from_medusa() with the mixed media profile returns nil for
        non-item content' do
    # access folder
    bogus = 'd7c201cf-876e-7768-bd95-6785666a180e'
    assert_nil MedusaMixedMediaIngester.parent_id_from_medusa(bogus)
    # preservation folder
    bogus = '7b292841-d8aa-c4e4-6561-eb8f3cb6d00c'
    assert_nil MedusaMixedMediaIngester.parent_id_from_medusa(bogus)
  end

end
