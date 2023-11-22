require 'test_helper'

class MedusaIngesterTest < ActiveSupport::TestCase

  setup do
    @instance = MedusaIngester.new
    setup_opensearch
  end

  # create_items() is tested in the package profile-specific implementations

  # delete_missing_items() is tested in the package profile-specific implementations

  # recreate_binaries() is tested in the package profile-specific implementations

  # replace_metadata() is tested in the package profile-specific implementations

  # sync_collections()

  test 'sync_collections() creates new collections' do
    Collection.destroy_all
    @instance.sync_collections
    assert Collection.count >= 5
  end

  test 'sync_collections() updates existing collections' do
    new_description = 'This should get replaced'
    collection = collections(:compound_object)
    collection.update!(description_html: new_description)
    @instance.sync_collections
    collection.reload
    assert_not_equal new_description, collection.description_html
  end

  test 'sync_collections() deletes collections not present in Medusa' do
    collection = Collection.create!(repository_id: SecureRandom.uuid)
    @instance.sync_collections
    assert_raises ActiveRecord::RecordNotFound do
      collection.reload
    end
  end

  # sync_items() is tested in the package profile-specific implementations

end
