require 'csv'

class ItemTsvIngester

  ##
  # Creates or updates items from the given TSV string.
  #
  # @param tsv [String] TSV body string
  # @param collection [Collection]
  # @param task [Task] Optional
  # @return [Integer] Number of items ingested
  #
  def ingest_tsv(tsv, collection, task = nil)
    raise 'No TSV content provided.' unless tsv.present?
    raise 'No collection provided.' unless collection

    tsv = CSV.parse(tsv, headers: true, col_sep: "\t")
    total_count = tsv.length
    count = 0
    tsv.map{ |row| row.to_hash }.each do |row|
      item = Item.find_by_repository_id(row['uuid'])
      if item
        item.collection = collection
        item.update_from_tsv(row)
      else
        Item.from_tsv(row, collection)
      end
      count += 1

      if task and count % 10 == 0
        task.progress = count / total_count.to_f
      end
    end
    count
  end

  ##
  # Creates or updates items from the given TSV file.
  #
  # @param tsv_pathname [String] TSV file pathname
  # @param collection [Collection]
  # @param task [Task] Optional
  # @return [Integer] Number of items ingested
  #
  def ingest_tsv_file(tsv_pathname, collection, task = nil)
    ingest_tsv(File.read(tsv_pathname), collection, task)
  end

end
