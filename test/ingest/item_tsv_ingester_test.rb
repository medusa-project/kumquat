require 'test_helper'

class ItemTsvIngesterTest < ActiveSupport::TestCase

  setup do
    @ingester = ItemTsvIngester.new
  end

  test 'ingest_tsv should create new items from valid TSV' do
    tsv = "repositoryId\tcollectionId\ttitle\n"
    tsv += "001\tcollection1\tCats\n"
    tsv += "002\tcollection1\tMore cats\n"
    tsv += "003\tcollection1\tEven more cats\n"
    assert_equal 3, @ingester.ingest_tsv(tsv)

    assert_equal 3, Item.where("repository_id IN ('001', '002', '003')").count
    assert_equal 'Cats', Item.find_by_repository_id('001').title
  end

  test 'ingest_tsv should update existing items from valid TSV' do
    initial_count = Item.all.count

    tsv = "repositoryId\tcollectionId\ttitle\n"
    tsv += "item1\tcollection1\tFrom fixture\n"
    tsv += "item2\tcollection1\tFrom fixture\n"
    @ingester.ingest_tsv(tsv)

    assert_equal initial_count, Item.all.count
  end

  test 'ingest_tsv should raise an error with empty TSV argument' do
    assert_raises RuntimeError do
      @ingester.ingest_tsv(nil)
    end
  end

  test 'ingest_tsv should raise an error with missing value' do
    tsv = "collectionId\ttitle\n"
    tsv += "collection1\tFrom fixture\n"
    tsv += "collection2\tFrom fixture\n"
    assert_raises ActiveRecord::RecordInvalid do
      @ingester.ingest_tsv(tsv)
    end
  end

  test 'ingest_tsv should raise an error with blank value' do
    tsv = "repositoryId\tcollectionId\ttitle\n"
    tsv += "item1\t\tFrom fixture\n"
    tsv += "item2\t\tFrom fixture\n"
    assert_raises ActiveRecord::RecordInvalid do
      @ingester.ingest_tsv(tsv)
    end
  end

end
