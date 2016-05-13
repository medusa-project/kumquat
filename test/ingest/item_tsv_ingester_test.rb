require 'test_helper'

class ItemTsvIngesterTest < ActiveSupport::TestCase

  setup do
    @ingester = ItemTsvIngester.new
    @collection = collections(:collection1)
  end

  test 'ingest_tsv should create new items from valid TSV' do
    tsv = "uuid\tcollectionId\ttitle\r\n"
    tsv += "001\tcollection1\tCats\r\n"
    tsv += "002\tcollection1\tMore cats\r\n"
    tsv += "003\tcollection1\tEven more cats\r\n"
    assert_equal 3, @ingester.ingest_tsv(tsv, @collection)

    assert_equal 3, Item.where("repository_id IN ('001', '002', '003')").count
    assert_equal 'Cats', Item.find_by_repository_id('001').title
  end

  test 'ingest_tsv should update existing items from valid TSV' do
    initial_count = Item.all.count

    tsv = "uuid\tcollectionId\ttitle\r\n"
    tsv += "item1\tcollection1\tFrom fixture\r\n"
    tsv += "item2\tcollection1\tFrom fixture\r\n"
    @ingester.ingest_tsv(tsv, @collection)

    assert_equal initial_count, Item.all.count
  end

  test 'ingest_tsv should raise an error with empty TSV argument' do
    assert_raises RuntimeError do
      @ingester.ingest_tsv(nil, @collection)
    end
  end

  test 'ingest_tsv should raise an error with empty collection argument' do
    tsv = "uuid\tcollectionId\ttitle\r\n"
    tsv += "item1\tcollection1\tFrom fixture\r\n"
    tsv += "item2\tcollection1\tFrom fixture\r\n"
    assert_raises RuntimeError do
      @ingester.ingest_tsv(tsv, nil)
    end
  end

  test 'ingest_tsv should raise an error with missing value' do
    tsv = "title\r\n"
    tsv += "Cats\r\n"
    tsv += "More cats\r\n"
    assert_raises ActiveRecord::RecordInvalid do
      @ingester.ingest_tsv(tsv, @collection)
    end
  end

  test 'ingest_tsv should raise an error with blank value' do
    tsv = "uuid\tcollectionId\ttitle\r\n"
    tsv += "newitem1\t\tCats\r\n"
    tsv += "newitem2\t\tMore cats\r\n"
    assert_raises ActiveRecord::RecordInvalid do
      @ingester.ingest_tsv(tsv, @collection)
    end
  end

end
