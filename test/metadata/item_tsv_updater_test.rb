require 'test_helper'

class ItemTsvUpdaterTest < ActiveSupport::TestCase

  setup do
    @instance = ItemTsvUpdater.new
    @tsv_pathname = __dir__ + '/../fixtures/repository/lincoln.tsv'
  end

  # ingest_pathname()

  test 'ingest_pathname should update items from valid TSV' do
    Item.destroy_all

    # Create the items
    tsv = File.read(@tsv_pathname)
    CSV.parse(tsv, headers: true, col_sep: "\t", quote_char: "\x00").
        map{ |row| row.to_hash }.each do |row|
      Item.create!(repository_id: row['uuid'],
                   collection_repository_id: 'd250c1f0-5ca8-0132-3334-0050569601ca-8')
    end

    assert_equal 6, @instance.ingest_pathname(@tsv_pathname)

    # Check their metadata
    assert_equal 'Meserve Lincoln Photograph No. 1',
                 Item.find_by_repository_id('06639370-0b08-0134-1d55-0050569601ca-4').title
  end

end
