require 'test_helper'

class ItemTsvIngesterTest < ActiveSupport::TestCase

  setup do
    @ingester = ItemTsvIngester.new

    @free_form_collection = collections(:collection1)
    @free_form_tsv = File.read(__dir__ + '/../fixtures/repository/medusa-free-form.tsv')
    @free_form_tsv_array = CSV.parse(@free_form_tsv, headers: true, col_sep: "\t").
        map{ |row| row.to_hash }

    @map_collection = collections(:collection2)
    @map_tsv = File.read(__dir__ + '/../fixtures/repository/medusa-map.tsv')
    @map_tsv_array = CSV.parse(@map_tsv, headers: true, col_sep: "\t").
        map{ |row| row.to_hash }
  end

  # dls_tsv?

  test 'dls_tsv? should return true for DLS TSV' do
    tsv = Item.tsv_header(metadata_profiles(:default_metadata_profile))
    tsv += Item.find_by_repository_id('a53add10-5ca8-0132-3334-0050569601ca-7').to_tsv
    tsv += Item.find_by_repository_id('6e406030-5ce3-0132-3334-0050569601ca-3').to_tsv
    dls_free_form_tsv = CSV.parse(tsv, headers: true, row_sep: "\n\r", col_sep: "\t").
        map{ |row| row.to_hash }
    tsv = Item.tsv_header(metadata_profiles(:default_metadata_profile))
    tsv += Item.find_by_repository_id('be8d3500-c451-0133-1d17-0050569601ca-9').to_tsv
    tsv += Item.find_by_repository_id('d29950d0-c451-0133-1d17-0050569601ca-2').to_tsv
    tsv += Item.find_by_repository_id('d29edba0-c451-0133-1d17-0050569601ca-c').to_tsv
    tsv += Item.find_by_repository_id('cd2d4601-c451-0133-1d17-0050569601ca-8').to_tsv
    dls_map_tsv = CSV.parse(tsv, headers: true, row_sep: "\n\r", col_sep: "\t").
        map{ |row| row.to_hash }

    assert ItemTsvIngester.dls_tsv?(dls_free_form_tsv)
    assert ItemTsvIngester.dls_tsv?(dls_map_tsv)
  end

  test 'dls_tsv? should return false for Medusa TSV' do
    assert !ItemTsvIngester.dls_tsv?(@free_form_tsv_array)
    assert !ItemTsvIngester.dls_tsv?(@map_tsv_array)
  end

  # parent_directory_id

  test 'parent_directory_id should return nil for files/directories with no
        parent' do
    assert_nil ItemTsvIngester.parent_directory_id('431d6090-5ca7-0132-3334-0050569601ca-a',
                                                   @free_form_tsv_array)
  end

  test 'parent_directory_id should return the correct parent ID for
        files/directories with a parent' do
    assert_equal '431d6090-5ca7-0132-3334-0050569601ca-a',
                 ItemTsvIngester.parent_directory_id('a52b2e40-5ca8-0132-3334-0050569601ca-c',
                                                     @free_form_tsv_array)
    assert_equal 'a53add10-5ca8-0132-3334-0050569601ca-7',
                 ItemTsvIngester.parent_directory_id('6e3c33c0-5ce3-0132-3334-0050569601ca-f',
                                                     @free_form_tsv_array)
  end

  # within_root?

  test 'within_root? should return false for items that are not within a
        collection\'s effective root' do
    assert !ItemTsvIngester.within_root?('431d6090-5ca7-0132-3334-0050569601ca-a',
                                         @free_form_collection, @free_form_tsv_array)
    assert !ItemTsvIngester.within_root?('a530c1f0-5ca8-0132-3334-0050569601ca-8',
                                         @free_form_collection, @free_form_tsv_array)
  end

  test 'within_root? should return true for items that are within a collection\'s
        effective root' do
    assert ItemTsvIngester.within_root?('a53194a0-5ca8-0132-3334-0050569601ca-8',
                                        @free_form_collection, @free_form_tsv_array)
    assert ItemTsvIngester.within_root?('6e412540-5ce3-0132-3334-0050569601ca-a',
                                        @free_form_collection, @free_form_tsv_array)
  end

  # ingest_tsv

  test 'ingest_tsv should raise an error with empty TSV argument' do
    assert_raises RuntimeError do
      @ingester.ingest_tsv(nil, @free_form_collection)
    end
  end

  test 'ingest_tsv should raise an error with collection with no content profile assigned' do
    assert_raises RuntimeError do
      @free_form_collection.content_profile = nil
      @ingester.ingest_tsv(@free_form_tsv, @free_form_collection)
    end
  end

  test 'ingest_tsv should create new items from valid TSV' do
    assert_equal 45, @ingester.ingest_tsv(@free_form_tsv, @free_form_collection)
  end

  test 'ingest_tsv should update existing items from valid TSV' do
    initial_count = Item.all.count

    tsv = "uuid\ttitle\r\n"
    tsv += "item1\tFrom fixture\r\n"
    tsv += "item2\tFrom fixture\r\n"
    @ingester.ingest_tsv(tsv, @free_form_collection)

    assert_equal initial_count, Item.all.count
  end

end
