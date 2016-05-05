require 'csv'

class ItemTsvIngester

  ##
  # Creates or updates items from the given TSV string.
  #
  # @param tsv [String] TSV body string
  # @param task [Task] Optional
  # @return [Integer] Number of items ingested
  #
  def ingest_tsv(tsv, task = nil)
    raise 'No TSV content specified.' unless tsv.present?
    # quote_char needs to be a character that the source data is guaranteed
    # not to contain: in this case, a unicode rocket ship.
    tsv = CSV.parse(tsv, headers: true, col_sep: "\t", quote_char: '🚀')
    total_count = tsv.length
    count = 0
    tsv.map{ |row| row.to_hash }.select{ |row| row['repositoryId'].present? }.each do |row|
      item = Item.find_by_repository_id(row['repositoryId'])
      if item
        item.update_from_tsv(row)
      else
        Item.from_tsv(row)
      end
      count += 1

      task.progress = count / total_count.to_f if task
    end

    task.succeeded if task
    count
  end

  ##
  # Creates or updates items from the given TSV file.
  #
  # @param tsv_pathname [String] TSV file pathname
  # @param task [Task] Optional
  # @return [Integer] Number of items ingested
  #
  def ingest_tsv_file(tsv_pathname, task = nil)
    ingest_tsv(File.read(tsv_pathname), task)
  end

end
