require 'test_helper'

class MedusaIngesterTest < ActiveSupport::TestCase

  setup do
    @instance = MedusaIngester.new

    # These will only get in the way.
    Item.destroy_all
  end

  test 'sync_collections() should work' do
    # TODO: write this
  end

  test 'sync_items() should work' do
    # TODO: write this
  end

end
