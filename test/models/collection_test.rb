require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  def setup
    @col = Collection.new
    @col.repository_id = '162'
  end

end
