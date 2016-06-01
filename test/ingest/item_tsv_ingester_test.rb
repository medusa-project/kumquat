require 'test_helper'

class ItemTsvIngesterTest < ActiveSupport::TestCase

  setup do
    @ingester = ItemTsvIngester.new
    @collection = collections(:collection1)

    @tsv = File.read(__dir__ + '/../fixtures/repository/medusa-free-form.tsv')
    @tsv_hash = CSV.parse(@tsv, headers: true, col_sep: "\t").
        map{ |row| row.to_hash }
  end

  # parent_directory_id

  test 'parent_directory_id should return nil for files/directories with no
        parent' do
    assert_nil ItemTsvIngester.parent_directory_id('431d6090-5ca7-0132-3334-0050569601ca-a', @tsv_hash)
  end

  test 'parent_directory_id should return the correct parent ID for
        files/directories with a parent' do
    assert_equal '431d6090-5ca7-0132-3334-0050569601ca-a',
                 ItemTsvIngester.parent_directory_id('a52b2e40-5ca8-0132-3334-0050569601ca-c', @tsv_hash)
    assert_equal 'a53add10-5ca8-0132-3334-0050569601ca-7',
                 ItemTsvIngester.parent_directory_id('6e3c33c0-5ce3-0132-3334-0050569601ca-f', @tsv_hash)
  end

  # within_root?

  test 'within_root? should return false for items that are not within a
        collection\'s effective root' do
    assert !ItemTsvIngester.within_root?('431d6090-5ca7-0132-3334-0050569601ca-a',
                                         @collection, @tsv_hash)
    assert !ItemTsvIngester.within_root?('a530c1f0-5ca8-0132-3334-0050569601ca-8',
                                         @collection, @tsv_hash)
  end

  test 'within_root? should return true for items that are within a collection\'s
        effective root' do
    assert ItemTsvIngester.within_root?('a53194a0-5ca8-0132-3334-0050569601ca-8',
                                        @collection, @tsv_hash)
    assert ItemTsvIngester.within_root?('6e412540-5ce3-0132-3334-0050569601ca-a',
                                        @collection, @tsv_hash)
  end

  # ingest_tsv

  test 'ingest_tsv should create new items from valid TSV' do
    assert_equal 45, @ingester.ingest_tsv(@tsv, @collection)
  end

  test 'ingest_tsv should update existing items from valid TSV' do
    initial_count = Item.all.count

    tsv = "uuid\ttitle\r\n"
    tsv += "item1\tFrom fixture\r\n"
    tsv += "item2\tFrom fixture\r\n"
    @ingester.ingest_tsv(tsv, @collection)

    assert_equal initial_count, Item.all.count
  end

  test 'ingest_tsv should raise an error with empty TSV argument' do
    assert_raises RuntimeError do
      @ingester.ingest_tsv(nil, @collection)
    end
  end

  test 'ingest_tsv should set the variant for free-form content ingested from
        Medusa' do
    @ingester.ingest_tsv(@tsv, @collection)
    assert_equal Item::Variants::DIRECTORY,
                 Item.find_by_repository_id('a53a0ce0-5ca8-0132-3334-0050569601ca-9').variant
    assert_equal Item::Variants::FILE,
                 Item.find_by_repository_id('6e3c33c0-5ce3-0132-3334-0050569601ca-f').variant
  end

end
