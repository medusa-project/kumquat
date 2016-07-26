require 'test_helper'

class ItemTsvIngesterTest < ActiveSupport::TestCase

  setup do
    @ingester = ItemTsvIngester.new
    @tsv = File.read(__dir__ + '/../fixtures/repository/lincoln.tsv')
    @tsv_array = CSV.parse(@tsv, headers: true, col_sep: "\t", quote_char: "\x00").
        map{ |row| row.to_hash }
  end

  # ingest_tsv

  test 'ingest_tsv should raise an error with empty TSV argument' do
    assert_raises RuntimeError do
      @ingester.ingest_tsv(nil)
    end
  end

  test 'ingest_tsv should update items from valid TSV' do
    Item.destroy_all

    # Create the items
    @tsv_array.each do |row|
      Item.create!(repository_id: row['uuid'],
                   collection_repository_id: 'd250c1f0-5ca8-0132-3334-0050569601ca-8')
    end

    assert_equal 6, @ingester.ingest_tsv(@tsv)

    # Check their metadata
    assert_equal 'Meserve Lincoln Photograph No. 1',
                 Item.find_by_repository_id('06639370-0b08-0134-1d55-0050569601ca-4').title
  end

end
